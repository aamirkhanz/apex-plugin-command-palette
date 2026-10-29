-- Command Palette region plug-in (TechRevX, www.techrevx.com)
-- render: the search button (Display = Search Button) and techrevx.commandPalette.init (command-palette.js).
--         Commands are not part of the page: the palette asks for them the first time it opens.
-- ajax:   x01 = LIST returns the commands of the region source:
--         t (title), l (link, substitutions replaced), g (group), i (icon), d (description), k (keywords),
--         s (shortcut), v (value), a (apex.actions name).

c_column_attrs constant apex_t_varchar2 := apex_t_varchar2(
    'TITLE_COLUMN', 'LINK_COLUMN', 'GROUP_COLUMN', 'ICON_COLUMN', 'DESCRIPTION_COLUMN',
    'KEYWORDS_COLUMN', 'SHORTCUT_COLUMN', 'VALUE_COLUMN', 'ACTION_COLUMN' );
c_column_keys constant apex_t_varchar2 := apex_t_varchar2( 't', 'l', 'g', 'i', 'd', 'k', 's', 'v', 'a' );

procedure write_commands( p_region in apex_plugin.t_region ) is
    l_names   apex_t_varchar2 := apex_t_varchar2();
    l_pos     apex_t_number   := apex_t_number();
    l_columns apex_exec.t_columns;
    l_context apex_exec.t_context;
    l_added   boolean;
    l_value   varchar2( 32767 );
begin
    l_names.extend( c_column_attrs.count );
    l_pos.extend( c_column_attrs.count );
    for i in 1 .. c_column_attrs.count loop
        l_names( i ) := p_region.attributes.get_varchar2( c_column_attrs( i ) );
        if l_names( i ) is not null then
            l_added := false;
            for j in 1 .. i - 1 loop
                l_added := l_added or nvl( l_names( j ) = l_names( i ), false );
            end loop;
            if not l_added then
                apex_exec.add_column( p_columns => l_columns, p_column_name => l_names( i ) );
            end if;
        end if;
    end loop;

    l_context := apex_exec.open_query_context( p_columns => l_columns, p_max_rows => 5000 );
    for i in 1 .. c_column_attrs.count loop
        if l_names( i ) is not null then
            l_pos( i ) := apex_exec.get_column_position( l_context, l_names( i ) );
            if l_pos( i ) is null then
                raise_application_error( -20001, 'Command Palette: column ' || l_names( i ) || ' is not in the region source of "' || p_region.name || '".' );
            end if;
        end if;
    end loop;

    apex_json.open_array( 'commands' );
    while apex_exec.next_row( l_context ) loop
        apex_json.open_object;
        for i in 1 .. c_column_attrs.count loop
            if l_pos( i ) is not null then
                l_value := apex_exec.get_varchar2( l_context, l_pos( i ) );
                if c_column_keys( i ) = 'l' and l_value is not null then
                    l_value := apex_plugin_util.replace_substitutions( p_value => l_value, p_escape => false );
                end if;
                apex_json.write( c_column_keys( i ), l_value );
            end if;
        end loop;
        apex_json.close_object;
    end loop;
    apex_json.close_array;
    apex_exec.close( l_context );
exception
    when others then
        apex_exec.close( l_context );
        raise;
end write_commands;

procedure render (
    p_plugin in            apex_plugin.t_plugin,
    p_region in            apex_plugin.t_region,
    p_param  in            apex_plugin.t_region_render_param,
    p_result in out nocopy apex_plugin.t_region_render_result )
is
    l_id          varchar2( 255 ) := apex_escape.html_attribute( p_region.static_id );
    l_placeholder varchar2( 4000 ) := nvl( apex_plugin_util.replace_substitutions( p_region.attributes.get_varchar2( 'PLACEHOLDER' ), false ), 'Search or jump to...' );
    l_display     varchar2( 30 ) := nvl( p_region.attributes.get_varchar2( 'DISPLAY' ), 'button' );
begin
    sys.htp.prn( '<div id="' || l_id || '_palette" class="tx-PaletteRegion">' );
    if l_display = 'button' then
        sys.htp.prn( '<button type="button" class="tx-PaletteBtn" aria-haspopup="dialog">'
            || '<span class="tx-PaletteBtn-icon fa fa-search" aria-hidden="true"></span>'
            || '<span class="tx-PaletteBtn-text">' || apex_escape.html( l_placeholder ) || '</span>'
            || '<kbd class="tx-PaletteBtn-key" hidden></kbd></button>' );
    end if;
    sys.htp.p( '</div>' );

    apex_javascript.add_onload_code( p_code =>
        'techrevx.commandPalette.init(' || apex_javascript.add_value( p_region.static_id ) || '{'
        || apex_javascript.add_attribute( 'ajaxIdentifier', apex_plugin.get_ajax_identifier )
        || apex_javascript.add_attribute( 'itemsToSubmit', apex_plugin_util.page_item_names_to_jquery( p_region.ajax_items_to_submit ) )
        || apex_javascript.add_attribute( 'title', p_region.name )
        || apex_javascript.add_attribute( 'placeholder', l_placeholder )
        || apex_javascript.add_attribute( 'display', l_display )
        || apex_javascript.add_attribute( 'sources', p_region.attributes.get_varchar2( 'SOURCES' ) )
        || apex_javascript.add_attribute( 'shortcut', p_region.attributes.get_varchar2( 'SHORTCUT_KEY' ) )
        || apex_javascript.add_attribute( 'setItem', p_region.attributes.get_varchar2( 'SET_ITEM' ) )
        || apex_javascript.add_attribute( 'recent', nvl( p_region.attributes.get_number( 'RECENT' ), 5 ) )
        || apex_javascript.add_attribute( 'maxResults', nvl( p_region.attributes.get_number( 'MAX_RESULTS' ), 60 ) )
        || apex_javascript.add_attribute( 'appId', v( 'APP_ID' ), false, false )
        || '});' );
end render;

procedure ajax (
    p_plugin in            apex_plugin.t_plugin,
    p_region in            apex_plugin.t_region,
    p_param  in            apex_plugin.t_region_ajax_param,
    p_result in out nocopy apex_plugin.t_region_ajax_result )
is
begin
    apex_json.open_object;
    write_commands( p_region );
    apex_json.close_object;
end ajax;
