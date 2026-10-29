/*
 * Command Palette region plug-in for Oracle APEX (TechRevX, www.techrevx.com)
 *
 * techrevx.commandPalette.init( regionId, options ) is called by the render procedure. The palette dialog is built
 * on first use and appended to <body>. Commands come from:
 *   the region source   loaded with x01=LIST the first time the palette opens (refresh() loads them again)
 *   addCommands()       commands added with JavaScript, which may run a function
 *   the Navigation Menu read from the rendered menu (#t_TreeNav), so conditions and authorization already apply
 *   page actions        the labelled apex.actions of the page
 *
 * Command: { t: title, path, l: link, g: group, i: icon, d: description, k: keywords, s: shortcut, v: value,
 *            a: apex.actions name, fn: function }
 *
 * apex.region( id ).open( query ) / close() / toggle() / refresh() / addCommands( commands )
 * Events on the region: tx-commandpalette-open, tx-commandpalette-close,
 *   tx-commandpalette-select { title, value, group, link, action }
 */
( function( $, apex ) {
    "use strict";

    const ns = window.techrevx = window.techrevx || {},
        IS_MAC = /Mac|iPhone|iPad/.test( navigator.platform || navigator.userAgent ),
        WORD_START = /[\s\-_/.:(,›]/;
    let openPalette = null;

    function el( tag, cls, text ) {
        const e = document.createElement( tag );
        if ( cls ) { e.className = cls; }
        if ( text != null ) { e.textContent = text; }
        return e;
    }

    function norm( s ) { return s == null ? "" : String( s ).toLowerCase(); }

    // "Ctrl+Shift+K" -> { ctrl, shift, alt, key: "k" }; "/" -> { key: "/" }
    function parseShortcut( text ) {
        if ( !text || !String( text ).trim() ) { return null; }
        const sc = { ctrl: false, shift: false, alt: false, key: "" };
        String( text ).split( /\+(?!$)/ ).map( p => p.trim() ).forEach( p => {
            const l = p.toLowerCase();
            if ( [ "ctrl", "control", "cmd", "command", "meta", "mod" ].includes( l ) ) { sc.ctrl = true; }
            else if ( l === "shift" ) { sc.shift = true; }
            else if ( l === "alt" || l === "option" ) { sc.alt = true; }
            else { sc.key = l; }
        } );
        return sc.key ? sc : null;
    }

    function matchesShortcut( sc, e ) {
        const mod = IS_MAC ? e.metaKey || e.ctrlKey : e.ctrlKey && !e.metaKey;
        if ( sc.ctrl !== mod || sc.alt !== e.altKey ) { return false; }
        // Shift is part of letters, digits and named keys; for symbols such as / or ? the layout decides
        if ( /^[a-z0-9]$/.test( sc.key ) || sc.key.length > 1 ) {
            if ( sc.shift !== e.shiftKey ) { return false; }
            return norm( e.key ) === sc.key || norm( e.code ) === "key" + sc.key || norm( e.code ) === "digit" + sc.key;
        }
        return e.key === sc.key;
    }

    function shortcutLabel( sc ) {
        const p = [];
        if ( sc.ctrl ) { p.push( IS_MAC ? "⌘" : "Ctrl" ); }
        if ( sc.alt ) { p.push( IS_MAC ? "⌥" : "Alt" ); }
        if ( sc.shift ) { p.push( IS_MAC ? "⇧" : "Shift" ); }
        p.push( sc.key.length === 1 ? sc.key.toUpperCase() : sc.key.charAt( 0 ).toUpperCase() + sc.key.slice( 1 ) );
        return IS_MAC ? p.join( "" ) : p.join( " " );
    }

    function isEditable( t ) {
        return t && ( t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test( t.tagName ) );
    }

    // Where the letters of q appear in text, best first: a substring (at a word start is better), the first letters
    // of words ("kb" in Kanban Board), then the letters in order, starting from whichever position fits tightest.
    function findIn( q, text ) {
        const t = norm( text ), at = t.indexOf( q );
        if ( at >= 0 ) {
            const start = at === 0 || WORD_START.test( t[ at - 1 ] );
            return { score: 20 + ( at === 0 ? 10 : 0 ) + ( start ? 6 : 0 ) - Math.min( at, 10 ) * 0.2, idx: Array.from( { length: q.length }, ( _, i ) => at + i ) };
        }
        const initials = [];
        let k = 0;
        for ( let i = 0; i < t.length && k < q.length; i++ ) {
            if ( ( i === 0 || WORD_START.test( t[ i - 1 ] ) ) && t[ i ] === q[ k ] ) { initials.push( i ); k++; }
        }
        if ( k === q.length && q.length > 1 ) { return { score: 18 + q.length * 2, idx: initials }; }

        // letters spread out have to stay close together; two letters also have to start a word ("dm" in Demo)
        let best = null;
        for ( let s = t.indexOf( q[ 0 ] ); s >= 0; s = t.indexOf( q[ 0 ], s + 1 ) ) {
            const idx = [];
            let j = 0, score = 0, prev = -2;
            for ( let i = s; i < t.length && j < q.length; i++ ) {
                if ( t[ i ] === q[ j ] ) {
                    score += ( i === prev + 1 ? 3 : 1 ) + ( i === 0 || WORD_START.test( t[ i - 1 ] ) ? 2 : 0 );
                    idx.push( i );
                    prev = i;
                    j++;
                }
            }
            if ( j < q.length ) { break; } // later starts cannot fit either
            const span = idx[ idx.length - 1 ] - idx[ 0 ];
            if ( span > q.length * 4 ) { continue; }
            if ( q.length < 3 && ( span > 3 || !( idx[ 0 ] === 0 || WORD_START.test( t[ idx[ 0 ] - 1 ] ) ) ) ) { continue; }
            score -= span * 0.15;
            if ( !best || score > best.score ) { best = { score, idx }; }
        }
        return best;
    }

    function label( cmd ) { return cmd.path ? cmd.path + " › " + cmd.t : cmd.t; }

    // every word of the query has to match the label (path and title), or else the group, description or keywords;
    // marks are positions in the label
    function rank( cmd, tokens ) {
        let total = 0;
        const marks = new Set();
        for ( const tok of tokens ) {
            const m = findIn( tok, label( cmd ) );
            if ( m ) {
                total += m.score * 2;
                m.idx.forEach( i => marks.add( i ) );
                continue;
            }
            if ( norm( [ cmd.g, cmd.d, cmd.k ].join( " " ) ).includes( tok ) ) {
                total += 8;
                continue;
            }
            return null;
        }
        return { score: total, marks };
    }

    function command( c, src ) {
        const cmd = {
            t: c.t != null ? String( c.t ) : c.title != null ? String( c.title ) : "",
            path: c.path || "",
            l: c.l || c.link || "",
            g: c.g || c.group || "",
            i: c.i || c.icon || "",
            d: c.d || c.description || "",
            k: c.k || c.keywords || "",
            s: c.s || c.shortcut || "",
            v: c.v != null ? c.v : c.value,
            a: c.a || ( typeof c.action === "string" ? c.action : "" ),
            fn: typeof c.action === "function" ? c.action : null,
            src
        };
        cmd.key = [ cmd.g, cmd.path, cmd.t, cmd.l || cmd.a || ( cmd.v != null ? cmd.v : "" ) ].join( "|" );
        return cmd;
    }

    // the app's navigation menu as rendered for this user
    function navCommands() {
        const out = [], seen = new Set();
        const add = ( label, link, icon, path ) => {
            label = ( label || "" ).trim();
            if ( !label || !link || link === "#" || /^separator$/i.test( link ) || seen.has( path + label + link ) ) { return; }
            seen.add( path + label + link );
            out.push( command( { t: label, l: link, i: icon || "fa-file-o", path, g: "Pages" }, "nav" ) );
        };
        const tree = $( "#t_TreeNav" );
        if ( tree.length ) {
            try {
                const a = tree.treeView( "getNodeAdapter" );
                const walk = ( n, path ) => {
                    for ( let i = 0; i < a.childCount( n ); i++ ) {
                        const c = a.child( n, i ), label = a.getLabel( c );
                        add( label, c.link || ( a.getLink ? a.getLink( c ) : "" ), c.icon || ( a.getIcon ? a.getIcon( c ) : "" ), path.join( " › " ) );
                        if ( a.hasChildren( c ) ) { walk( c, path.concat( label ) ); }
                    }
                };
                walk( a.root(), [] );
            } catch ( e ) {
                // not a treeView (yet): read the links below
            }
        }
        if ( !out.length ) {
            document.querySelectorAll( "#t_TreeNav a[href], .t-Header-nav a[href]" ).forEach( link => add( link.textContent, link.getAttribute( "href" ), "", "" ) );
        }
        return out;
    }

    function actionCommands() {
        const out = [];
        ( apex.actions.list ? apex.actions.list() : [] ).forEach( item => {
            const action = apex.actions.lookup( item.name );
            if ( !action || !item.label || action.hide || action.disabled || /^tx-/.test( item.name ) ) { return; }
            out.push( command( { t: item.label, a: item.name, i: action.icon || "fa-bolt", s: action.shortcut || "", g: "Actions on this page" }, "actions" ) );
        } );
        return out;
    }

    class Palette {
        constructor( regionId, options ) {
            this.regionId = regionId;
            this.o = options;
            this.sources = String( options.sources || "" ).split( ":" );
            this.shortcut = parseShortcut( options.shortcut );
            this.jsCommands = [];
            this.server = null;
            this.items = [];
            this.active = -1;
            this.isOpen = false;
            this.storeKey = "tx-palette:" + options.appId + ":" + regionId;

            const btn = document.querySelector( "#" + CSS.escape( regionId ) + "_palette .tx-PaletteBtn" );
            if ( btn ) {
                const key = btn.querySelector( ".tx-PaletteBtn-key" );
                if ( this.shortcut && key ) {
                    key.textContent = shortcutLabel( this.shortcut );
                    key.hidden = false;
                    btn.setAttribute( "aria-keyshortcuts", ( this.shortcut.ctrl ? ( IS_MAC ? "Meta+" : "Control+" ) : "" ) + ( this.shortcut.shift ? "Shift+" : "" ) + this.shortcut.key.toUpperCase() );
                }
                btn.addEventListener( "click", () => this.open() );
            }
            if ( this.shortcut ) {
                document.addEventListener( "keydown", e => {
                    if ( e.defaultPrevented || e.isComposing || !matchesShortcut( this.shortcut, e ) ) { return; }
                    // a single key such as / is typed text inside fields, the palette's own search box included
                    if ( !this.shortcut.ctrl && !this.shortcut.alt && isEditable( e.target ) ) { return; }
                    e.preventDefault();
                    this.toggle();
                } );
            }
        }

        build() {
            const id = this.regionId + "_dialog";
            this.root = el( "div", "tx-Palette" );
            this.root.hidden = true;
            const backdrop = el( "div", "tx-Palette-backdrop" );
            backdrop.addEventListener( "mousedown", () => this.close() );

            this.dialog = el( "div", "tx-Palette-dialog" );
            this.dialog.id = id;
            this.dialog.setAttribute( "role", "dialog" );
            this.dialog.setAttribute( "aria-modal", "true" );
            this.dialog.setAttribute( "aria-label", this.o.title || "Command palette" );

            const bar = el( "div", "tx-Palette-search" ),
                icon = el( "span", "tx-Palette-searchIcon fa fa-search" ),
                esc = el( "kbd", "tx-Palette-esc", "Esc" );
            icon.setAttribute( "aria-hidden", "true" );
            this.input = el( "input", "tx-Palette-input" );
            this.input.type = "text";
            this.input.placeholder = this.o.placeholder || "Search or jump to...";
            this.input.autocomplete = "off";
            this.input.spellcheck = false;
            this.input.setAttribute( "role", "combobox" );
            this.input.setAttribute( "aria-expanded", "true" );
            this.input.setAttribute( "aria-controls", id + "_list" );
            this.input.setAttribute( "aria-autocomplete", "list" );
            this.input.setAttribute( "aria-label", this.o.placeholder || "Search commands" );
            this.input.addEventListener( "input", () => this.render() );
            this.input.addEventListener( "keydown", e => this.onKey( e ) );
            esc.setAttribute( "aria-hidden", "true" );
            esc.addEventListener( "click", () => this.close() );
            bar.append( icon, this.input, esc );

            this.list = el( "div", "tx-Palette-list" );
            this.list.id = id + "_list";
            this.list.setAttribute( "role", "listbox" );
            this.list.setAttribute( "aria-label", "Commands" );
            this.list.addEventListener( "mousemove", e => {
                const opt = e.target.closest( ".tx-Palette-item" );
                if ( opt && ( e.movementX || e.movementY ) ) { this.setActive( +opt.dataset.index, false ); }
            } );
            this.list.addEventListener( "click", e => {
                const opt = e.target.closest( ".tx-Palette-item" );
                if ( opt ) { this.run( this.items[ +opt.dataset.index ], e.ctrlKey || e.metaKey ); }
            } );
            this.list.addEventListener( "mousedown", e => e.preventDefault() ); // keep the focus in the search box

            this.status = el( "div", "tx-Palette-status" );
            this.status.setAttribute( "role", "status" );

            const foot = el( "div", "tx-Palette-foot" );
            [ [ "↑↓", "to move" ], [ "↵", "to open" ], [ "Esc", "to close" ] ].forEach( h => {
                const span = el( "span" );
                span.append( el( "kbd", null, h[ 0 ] ), " " + h[ 1 ] );
                foot.append( span );
            } );
            foot.setAttribute( "aria-hidden", "true" );

            this.dialog.append( bar, this.list, this.status, foot );
            this.dialog.addEventListener( "keydown", e => {
                if ( e.key === "Tab" ) { e.preventDefault(); this.input.focus(); }
            } );
            this.root.append( backdrop, this.dialog );
            document.body.append( this.root );
        }

        toggle() { if ( this.isOpen ) { this.close(); } else { this.open(); } }

        open( query ) {
            if ( openPalette && openPalette !== this ) { openPalette.close( false ); }
            if ( !this.root ) { this.build(); }
            if ( !this.isOpen ) {
                this.lastFocus = document.activeElement;
                this.isOpen = true;
                openPalette = this;
                this.root.hidden = false;
                document.documentElement.classList.add( "tx-Palette-lock" );
                requestAnimationFrame( () => this.root.classList.add( "is-open" ) );
                apex.event.trigger( "#" + this.regionId, "tx-commandpalette-open" );
            }
            this.input.value = query || "";
            this.input.focus();
            this.load().always( () => this.render() );
            this.render();
        }

        close( restoreFocus ) {
            if ( !this.isOpen ) { return; }
            this.isOpen = false;
            if ( openPalette === this ) { openPalette = null; }
            this.root.classList.remove( "is-open" );
            this.root.hidden = true;
            document.documentElement.classList.remove( "tx-Palette-lock" );
            if ( restoreFocus !== false && this.lastFocus && this.lastFocus.focus ) { this.lastFocus.focus(); }
            apex.event.trigger( "#" + this.regionId, "tx-commandpalette-close" );
        }

        // the region source's commands, once; refresh() asks again
        load() {
            if ( this.server ) { return this.server; }
            this.loading = true;
            this.server = apex.server.plugin( this.o.ajaxIdentifier, { x01: "LIST", pageItems: this.o.itemsToSubmit }, { dataType: "json" } )
                .done( data => { this.serverCommands = ( data.commands || [] ).map( c => command( c, "query" ) ); this.failed = false; } )
                .fail( () => { this.serverCommands = []; this.failed = true; this.server = null; } )
                .always( () => { this.loading = false; } );
            return this.server;
        }

        refresh() {
            this.server = null;
            const p = this.load();
            if ( this.isOpen ) { p.always( () => this.render() ); }
            return p;
        }

        addCommands( list ) {
            ( Array.isArray( list ) ? list : [ list ] ).forEach( c => this.jsCommands.push( command( c, "js" ) ) );
            if ( this.isOpen ) { this.render(); }
        }

        allCommands() {
            return [].concat(
                this.sources.includes( "nav" ) ? navCommands() : [],
                this.serverCommands || [],
                this.jsCommands,
                this.sources.includes( "actions" ) ? actionCommands() : []
            );
        }

        recentKeys() {
            try { return JSON.parse( localStorage.getItem( this.storeKey ) || "[]" ); } catch ( e ) { return []; }
        }

        remember( cmd ) {
            if ( !( this.o.recent > 0 ) ) { return; }
            const keys = [ cmd.key ].concat( this.recentKeys().filter( k => k !== cmd.key ) ).slice( 0, this.o.recent );
            try { localStorage.setItem( this.storeKey, JSON.stringify( keys ) ); } catch ( e ) { /* private mode */ }
        }

        render() {
            if ( !this.root ) { return; }
            const all = this.allCommands(),
                q = norm( this.input.value ).trim(),
                max = this.o.maxResults || 60;
            let sections;
            if ( q ) {
                const tokens = q.split( /\s+/ );
                const hits = all.map( ( cmd, n ) => ( { cmd, n, r: rank( cmd, tokens ) } ) ).filter( h => h.r )
                    .sort( ( a, b ) => b.r.score - a.r.score || a.n - b.n ).slice( 0, max );
                sections = [ { label: "", items: hits.map( h => ( { cmd: h.cmd, marks: h.r.marks } ) ), showGroup: true } ];
            } else {
                sections = [];
                const byKey = new Map( all.map( c => [ c.key, c ] ) );
                const recent = this.recentKeys().map( k => byKey.get( k ) ).filter( Boolean ).slice( 0, this.o.recent || 0 );
                if ( recent.length ) { sections.push( { label: "Recent", items: recent.map( cmd => ( { cmd } ) ), showGroup: true } ); }
                const groups = new Map();
                all.forEach( c => {
                    const g = c.g || "Commands";
                    if ( !groups.has( g ) ) { groups.set( g, [] ); }
                    groups.get( g ).push( { cmd: c } );
                } );
                let room = max;
                groups.forEach( ( items, label ) => {
                    if ( room <= 0 ) { return; }
                    sections.push( { label, items: items.slice( 0, room ) } );
                    room -= items.length;
                } );
            }

            this.list.textContent = "";
            this.items = [];
            sections.forEach( ( sec, s ) => {
                if ( !sec.items.length ) { return; }
                const group = el( "div", "tx-Palette-group" );
                group.setAttribute( "role", "group" );
                if ( sec.label ) {
                    const head = el( "div", "tx-Palette-groupLabel", sec.label );
                    head.id = this.regionId + "_g" + s;
                    group.setAttribute( "aria-labelledby", head.id );
                    group.append( head );
                } else {
                    group.setAttribute( "aria-label", "Results" );
                }
                sec.items.forEach( it => {
                    group.append( this.option( it.cmd, it.marks, sec.showGroup, this.items.length ) );
                    this.items.push( it.cmd );
                } );
                this.list.append( group );
            } );

            let message = "";
            if ( !this.items.length ) {
                message = this.loading ? "Loading commands..." : this.failed ? "The commands could not be loaded."
                    : q ? "No commands match “" + this.input.value.trim() + "”." : "No commands.";
                this.list.append( el( "div", "tx-Palette-empty", message ) );
            }
            this.status.textContent = this.items.length ? this.items.length + ( this.items.length === 1 ? " command" : " commands" ) : message;
            this.setActive( this.items.length ? 0 : -1 );
        }

        option( cmd, marks, showGroup, index ) {
            const opt = el( "div", "tx-Palette-item" ),
                icon = el( "span", "tx-Palette-icon" ),
                main = el( "span", "tx-Palette-main" ),
                title = el( "span", "tx-Palette-title" );
            opt.id = this.regionId + "_opt" + index;
            opt.dataset.index = index;
            opt.setAttribute( "role", "option" );
            opt.setAttribute( "aria-selected", "false" );
            icon.setAttribute( "aria-hidden", "true" );
            icon.append( el( "span", "fa " + ( cmd.i || ( cmd.l ? "fa-arrow-right" : "fa-bolt" ) ) ) );

            // the label with matched letters in <mark>; the path part is muted
            const text = label( cmd ), split = cmd.path ? cmd.path.length + 3 : 0;
            const write = ( from, to, parent ) => {
                let run = "", inMark = false;
                const flush = () => {
                    if ( run ) { parent.append( inMark ? el( "mark", null, run ) : document.createTextNode( run ) ); }
                    run = "";
                };
                for ( let i = from; i < to; i++ ) {
                    const m = !!( marks && marks.has( i ) );
                    if ( m !== inMark ) { flush(); inMark = m; }
                    run += text[ i ];
                }
                flush();
            };
            if ( split ) {
                const p = el( "span", "tx-Palette-path" );
                write( 0, split, p );
                title.append( p );
            }
            write( split, text.length, title );
            main.append( title );
            if ( cmd.d ) { main.append( el( "span", "tx-Palette-desc", cmd.d ) ); }

            const meta = el( "span", "tx-Palette-meta" );
            if ( showGroup && cmd.g ) { meta.append( el( "span", "tx-Palette-tag", cmd.g ) ); }
            if ( cmd.s ) { meta.append( el( "kbd", "tx-Palette-kbd", cmd.s ) ); }
            opt.append( icon, main, meta );
            return opt;
        }

        setActive( index, scroll ) {
            const prev = this.list.querySelector( ".tx-Palette-item.is-active" );
            if ( prev ) { prev.classList.remove( "is-active" ); prev.setAttribute( "aria-selected", "false" ); }
            this.active = index;
            const opt = index >= 0 ? document.getElementById( this.regionId + "_opt" + index ) : null;
            if ( opt ) {
                opt.classList.add( "is-active" );
                opt.setAttribute( "aria-selected", "true" );
                this.input.setAttribute( "aria-activedescendant", opt.id );
                if ( scroll !== false ) { opt.scrollIntoView( { block: "nearest" } ); }
            } else {
                this.input.removeAttribute( "aria-activedescendant" );
            }
        }

        onKey( e ) {
            const n = this.items.length;
            if ( e.isComposing ) { return; }
            switch ( e.key ) {
                case "ArrowDown":
                    e.preventDefault();
                    if ( n ) { this.setActive( ( this.active + 1 ) % n ); }
                    break;
                case "ArrowUp":
                    e.preventDefault();
                    if ( n ) { this.setActive( ( this.active - 1 + n ) % n ); }
                    break;
                case "PageDown":
                    e.preventDefault();
                    if ( n ) { this.setActive( Math.min( n - 1, this.active + 8 ) ); }
                    break;
                case "PageUp":
                    e.preventDefault();
                    if ( n ) { this.setActive( Math.max( 0, this.active - 8 ) ); }
                    break;
                case "Enter":
                    e.preventDefault();
                    if ( this.active >= 0 ) { this.run( this.items[ this.active ], e.ctrlKey || e.metaKey ); }
                    break;
                case "Escape":
                    e.preventDefault();
                    e.stopPropagation();
                    this.close();
                    break;
            }
        }

        // newTab: Ctrl/Cmd + Enter or click opens a link in a new tab
        run( cmd, newTab ) {
            if ( !cmd ) { return; }
            this.remember( cmd );
            const link = cmd.l, external = newTab && link && !/^javascript:/i.test( link );
            this.close( !link || external );
            if ( this.o.setItem ) { apex.item( this.o.setItem ).setValue( cmd.v != null ? cmd.v : cmd.t ); }
            apex.event.trigger( "#" + this.regionId, "tx-commandpalette-select",
                { title: cmd.t, value: cmd.v != null ? cmd.v : null, group: cmd.g, link: link || null, action: cmd.a || null } );
            if ( cmd.fn ) {
                cmd.fn( cmd );
            } else if ( cmd.a && apex.actions.lookup( cmd.a ) ) {
                apex.actions.invoke( cmd.a );
            } else if ( external ) {
                window.open( new URL( link, document.baseURI ).href, "_blank", "noopener" );
            } else if ( link ) {
                apex.navigation.redirect( link );
            }
        }
    }

    const palettes = {};
    ns.commandPalette = {
        init( regionId, options ) {
            const p = new Palette( regionId, options );
            palettes[ regionId ] = p;
            apex.region.create( regionId, {
                type: "TechRevXCommandPalette",
                open: query => p.open( query ),
                close: () => p.close(),
                toggle: () => p.toggle(),
                refresh: () => p.refresh(),
                addCommands: list => p.addCommands( list ),
                isOpen: () => p.isOpen,
                widget: () => $( p.root || [] )
            } );
        },
        get: regionId => palettes[ regionId ]
    };
} )( apex.jQuery, apex );
