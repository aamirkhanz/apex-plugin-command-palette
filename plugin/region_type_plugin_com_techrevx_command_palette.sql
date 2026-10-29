prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.04.07'
,p_release=>'26.2.0'
,p_default_workspace_id=>6202419497391597
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'AAMIRKHANZ'
);
end;
/
 
prompt APPLICATION 100 - Apex Plug-ins
--
-- Application Export:
--   Application:     100
--   Name:            Apex Plug-ins
--   Date and Time:   09:17 Thursday October 29, 2026
--   Exported By:     AAMIRKHANZ
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 6205483822861062
--   Manifest End
--   Version:         26.2.0
--   Instance ID:     2400160207269871
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/region_type/com_techrevx_command_palette
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(6205483822861062)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.TECHREVX.COMMAND_PALETTE'
,p_display_name=>'Command Palette'
,p_apexlang_name=>'commandPalette'
,p_javascript_file_urls=>'#PLUGIN_FILES#command-palette.js'
,p_css_file_urls=>'#PLUGIN_FILES#command-palette.css'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- Command Palette region plug-in (TechRevX, www.techrevx.com)',
'-- render: the search button (Display = Search Button) and techrevx.commandPalette.init (command-palette.js).',
'--         Commands are not part of the page: the palette asks for them the first time it opens.',
'-- ajax:   x01 = LIST returns the commands of the region source:',
'--         t (title), l (link, substitutions replaced), g (group), i (icon), d (description), k (keywords),',
'--         s (shortcut), v (value), a (apex.actions name).',
'',
'c_column_attrs constant apex_t_varchar2 := apex_t_varchar2(',
'    ''TITLE_COLUMN'', ''LINK_COLUMN'', ''GROUP_COLUMN'', ''ICON_COLUMN'', ''DESCRIPTION_COLUMN'',',
'    ''KEYWORDS_COLUMN'', ''SHORTCUT_COLUMN'', ''VALUE_COLUMN'', ''ACTION_COLUMN'' );',
'c_column_keys constant apex_t_varchar2 := apex_t_varchar2( ''t'', ''l'', ''g'', ''i'', ''d'', ''k'', ''s'', ''v'', ''a'' );',
'',
'procedure write_commands( p_region in apex_plugin.t_region ) is',
'    l_names   apex_t_varchar2 := apex_t_varchar2();',
'    l_pos     apex_t_number   := apex_t_number();',
'    l_columns apex_exec.t_columns;',
'    l_context apex_exec.t_context;',
'    l_added   boolean;',
'    l_value   varchar2( 32767 );',
'begin',
'    l_names.extend( c_column_attrs.count );',
'    l_pos.extend( c_column_attrs.count );',
'    for i in 1 .. c_column_attrs.count loop',
'        l_names( i ) := p_region.attributes.get_varchar2( c_column_attrs( i ) );',
'        if l_names( i ) is not null then',
'            l_added := false;',
'            for j in 1 .. i - 1 loop',
'                l_added := l_added or nvl( l_names( j ) = l_names( i ), false );',
'            end loop;',
'            if not l_added then',
'                apex_exec.add_column( p_columns => l_columns, p_column_name => l_names( i ) );',
'            end if;',
'        end if;',
'    end loop;',
'',
'    l_context := apex_exec.open_query_context( p_columns => l_columns, p_max_rows => 5000 );',
'    for i in 1 .. c_column_attrs.count loop',
'        if l_names( i ) is not null then',
'            l_pos( i ) := apex_exec.get_column_position( l_context, l_names( i ) );',
'            if l_pos( i ) is null then',
'                raise_application_error( -20001, ''Command Palette: column '' || l_names( i ) || '' is not in the region source of "'' || p_region.name || ''".'' );',
'            end if;',
'        end if;',
'    end loop;',
'',
'    apex_json.open_array( ''commands'' );',
'    while apex_exec.next_row( l_context ) loop',
'        apex_json.open_object;',
'        for i in 1 .. c_column_attrs.count loop',
'            if l_pos( i ) is not null then',
'                l_value := apex_exec.get_varchar2( l_context, l_pos( i ) );',
'                if c_column_keys( i ) = ''l'' and l_value is not null then',
'                    l_value := apex_plugin_util.replace_substitutions( p_value => l_value, p_escape => false );',
'                end if;',
'                apex_json.write( c_column_keys( i ), l_value );',
'            end if;',
'        end loop;',
'        apex_json.close_object;',
'    end loop;',
'    apex_json.close_array;',
'    apex_exec.close( l_context );',
'exception',
'    when others then',
'        apex_exec.close( l_context );',
'        raise;',
'end write_commands;',
'',
'procedure render (',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_region in            apex_plugin.t_region,',
'    p_param  in            apex_plugin.t_region_render_param,',
'    p_result in out nocopy apex_plugin.t_region_render_result )',
'is',
'    l_id          varchar2( 255 ) := apex_escape.html_attribute( p_region.static_id );',
'    l_placeholder varchar2( 4000 ) := nvl( apex_plugin_util.replace_substitutions( p_region.attributes.get_varchar2( ''PLACEHOLDER'' ), false ), ''Search or jump to...'' );',
'    l_display     varchar2( 30 ) := nvl( p_region.attributes.get_varchar2( ''DISPLAY'' ), ''button'' );',
'begin',
'    sys.htp.prn( ''<div id="'' || l_id || ''_palette" class="tx-PaletteRegion">'' );',
'    if l_display = ''button'' then',
'        sys.htp.prn( ''<button type="button" class="tx-PaletteBtn" aria-haspopup="dialog">''',
'            || ''<span class="tx-PaletteBtn-icon fa fa-search" aria-hidden="true"></span>''',
'            || ''<span class="tx-PaletteBtn-text">'' || apex_escape.html( l_placeholder ) || ''</span>''',
'            || ''<kbd class="tx-PaletteBtn-key" hidden></kbd></button>'' );',
'    end if;',
'    sys.htp.p( ''</div>'' );',
'',
'    apex_javascript.add_onload_code( p_code =>',
'        ''techrevx.commandPalette.init('' || apex_javascript.add_value( p_region.static_id ) || ''{''',
'        || apex_javascript.add_attribute( ''ajaxIdentifier'', apex_plugin.get_ajax_identifier )',
'        || apex_javascript.add_attribute( ''itemsToSubmit'', apex_plugin_util.page_item_names_to_jquery( p_region.ajax_items_to_submit ) )',
'        || apex_javascript.add_attribute( ''title'', p_region.name )',
'        || apex_javascript.add_attribute( ''placeholder'', l_placeholder )',
'        || apex_javascript.add_attribute( ''display'', l_display )',
'        || apex_javascript.add_attribute( ''sources'', p_region.attributes.get_varchar2( ''SOURCES'' ) )',
'        || apex_javascript.add_attribute( ''shortcut'', p_region.attributes.get_varchar2( ''SHORTCUT_KEY'' ) )',
'        || apex_javascript.add_attribute( ''setItem'', p_region.attributes.get_varchar2( ''SET_ITEM'' ) )',
'        || apex_javascript.add_attribute( ''recent'', nvl( p_region.attributes.get_number( ''RECENT'' ), 5 ) )',
'        || apex_javascript.add_attribute( ''maxResults'', nvl( p_region.attributes.get_number( ''MAX_RESULTS'' ), 60 ) )',
'        || apex_javascript.add_attribute( ''appId'', v( ''APP_ID'' ), false, false )',
'        || ''});'' );',
'end render;',
'',
'procedure ajax (',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_region in            apex_plugin.t_region,',
'    p_param  in            apex_plugin.t_region_ajax_param,',
'    p_result in out nocopy apex_plugin.t_region_ajax_result )',
'is',
'begin',
'    apex_json.open_object;',
'    write_commands( p_region );',
'    apex_json.close_object;',
'end ajax;'))
,p_api_version=>3
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'SOURCE_LOCATION:AJAX_ITEMS_TO_SUBMIT:ORDER_BY'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Command Palette: A Ctrl+K search box that finds any page or command in your app and runs it from the keyboard.',
'',
'Commands: rows of the region source (title, link, group, icon, description, keywords, shortcut, value, action), plus the app''s Navigation Menu as the user sees it and, optionally, the page''s apex.actions. JavaScript can add commands with their own fu'
||'nction.',
'Search: fuzzy matching on titles, paths, descriptions and keywords, with the matched letters highlighted; recently used commands come first.',
'Running a command: opens its link, invokes its apex.actions action, sets Set Item and fires Command Palette - Command Selected for Dynamic Actions.',
'Keyboard: the shortcut (Ctrl+K by default, Cmd+K on a Mac) opens and closes it; arrow keys, Enter and Escape. Screen readers get a labelled dialog and listbox.',
'Put it on the Global Page with Display Hidden to have it on every page. JavaScript: apex.region( "id" ).open( query ), close(), refresh(), addCommands( commands ).',
'',
'No external libraries.',
'Documentation, updates and more plugins: https://www.techrevx.com'))
,p_version_identifier=>'1.0'
,p_about_url=>'https://www.techrevx.com'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Library: none, plain JavaScript',
'Opens with: Ctrl+K (Cmd+K on a Mac), or any shortcut you choose'))
,p_files_version=>2461343091607
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6205519693861062)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_title=>'Commands'
,p_apexlang_name=>'data'
,p_static_id=>'DATA'
,p_display_sequence=>10
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6205666609861062)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_title=>'Palette'
,p_apexlang_name=>'palette'
,p_static_id=>'PALETTE'
,p_display_sequence=>20
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6205709194861062)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>90
,p_static_id=>'ACTION_COLUMN'
,p_prompt=>'Action Column'
,p_apexlang_name=>'actionColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Name of an apex.actions action to invoke, for example a button''s action or an Interactive Grid action such as selection-add-row.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6205873928861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'DESCRIPTION_COLUMN'
,p_prompt=>'Description Column'
,p_apexlang_name=>'descriptionColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Short text under the title. Also searched.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6205966666861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>30
,p_static_id=>'DISPLAY'
,p_prompt=>'Display'
,p_apexlang_name=>'display'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'button'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_help_text=>'Search Button: a search field-like button in the region that opens the palette and shows the shortcut. Hidden: nothing is shown; open the palette with the shortcut or apex.region( id ).open(), for example in the Global Page.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6206036421861063)
,p_plugin_attribute_id=>wwv_flow_imp.id(6205966666861063)
,p_display_sequence=>10
,p_display_value=>'Search Button'
,p_return_value=>'button'
,p_apexlang_name=>'button'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6206176070861063)
,p_plugin_attribute_id=>wwv_flow_imp.id(6205966666861063)
,p_display_sequence=>20
,p_display_value=>'Hidden'
,p_return_value=>'hidden'
,p_apexlang_name=>'hidden'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206272299861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'GROUP_COLUMN'
,p_prompt=>'Group Column'
,p_apexlang_name=>'groupColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Heading the command is listed under, for example Pages, Create or Help. Groups appear in the order of the query.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206323741861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'ICON_COLUMN'
,p_prompt=>'Icon Column'
,p_apexlang_name=>'iconColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Font APEX icon class, for example fa-file-o.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206402111861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_static_id=>'KEYWORDS_COLUMN'
,p_prompt=>'Keywords Column'
,p_apexlang_name=>'keywordsColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Other words that find the command but are not shown, for example synonyms.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206569638861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'LINK_COLUMN'
,p_prompt=>'Link Column'
,p_apexlang_name=>'linkColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Where the command goes: a URL such as apex_page.get_url( p_page => 10 ), #APP_FILES#guide.pdf or javascript:... Substitutions are replaced.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206639297861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>16
,p_display_sequence=>70
,p_static_id=>'MAX_RESULTS'
,p_prompt=>'Maximum Results'
,p_apexlang_name=>'maxResults'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'60'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_help_text=>'Most commands listed at once; users type to narrow them down.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206762100861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>13
,p_display_sequence=>40
,p_static_id=>'PLACEHOLDER'
,p_prompt=>'Placeholder'
,p_apexlang_name=>'placeholder'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Search or jump to...'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_help_text=>'Text in the empty search box and on the button.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206896436861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>60
,p_static_id=>'RECENT'
,p_prompt=>'Recent Commands'
,p_apexlang_name=>'recent'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'5'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_help_text=>'How many recently used commands are shown first, kept in the browser. 0 turns it off.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6206926678861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>14
,p_display_sequence=>50
,p_static_id=>'SET_ITEM'
,p_prompt=>'Set Item'
,p_apexlang_name=>'setItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_help_text=>'Page item set to the command''s value (or its title) when a command is chosen, before the Command Selected event.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6207009858861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'SHORTCUT_COLUMN'
,p_prompt=>'Shortcut Column'
,p_apexlang_name=>'shortcutColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Keyboard shortcut shown next to the command, for example Ctrl+S. It is only displayed.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6207116003861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>20
,p_static_id=>'SHORTCUT_KEY'
,p_prompt=>'Keyboard Shortcut'
,p_apexlang_name=>'shortcutKey'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Ctrl+K'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_examples=>'Ctrl+K'
,p_help_text=>'Opens and closes the palette, for example Ctrl+K, Ctrl+Shift+P or /. On a Mac, Ctrl also accepts Cmd. A single key such as / only works outside text fields. Leave empty for none.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6207249253861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>10
,p_static_id=>'SOURCES'
,p_prompt=>'Also List'
,p_apexlang_name=>'sources'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'nav'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(6205666609861062)
,p_help_text=>'Navigation Menu: every page in the app''s navigation menu, as the user sees it (conditions and authorization apply), with its parent as the path. Page Actions: the labelled apex.actions of the current page, such as Interactive Grid actions.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6207435942861063)
,p_plugin_attribute_id=>wwv_flow_imp.id(6207249253861063)
,p_display_sequence=>20
,p_display_value=>'Page Actions'
,p_return_value=>'actions'
,p_apexlang_name=>'actions'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6207395752861063)
,p_plugin_attribute_id=>wwv_flow_imp.id(6207249253861063)
,p_display_sequence=>10
,p_display_value=>'Navigation Menu'
,p_return_value=>'nav'
,p_apexlang_name=>'nav'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6207522434861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'TITLE_COLUMN'
,p_prompt=>'Title Column'
,p_apexlang_name=>'titleColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'VARCHAR2:NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'What the command is called, for example Open orders. Searched first.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6207601949861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'VALUE_COLUMN'
,p_prompt=>'Value Column'
,p_apexlang_name=>'valueColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2:NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6205519693861062)
,p_help_text=>'Value passed to Set Item and to the Command Palette - Command Selected event, for commands handled by a Dynamic Action.'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6207764620861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_name=>'tx-commandpalette-close'
,p_display_name=>'Command Palette - Closed'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6207849292861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_name=>'tx-commandpalette-open'
,p_display_name=>'Command Palette - Opened'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6207994363861063)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_name=>'tx-commandpalette-select'
,p_display_name=>'Command Palette - Command Selected'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A20436F6D6D616E642050616C6574746520726567696F6E20706C75672D696E202854656368526576582C207777772E74656368726576782E636F6D29202A2F0A2E74782D50616C65747465526567696F6E2C0A2E74782D50616C65747465207B0A20';
wwv_flow_imp.g_varchar2_table(2) := '202D2D74782D63702D62673A20766172282D2D75742D636F6D706F6E656E742D6261636B67726F756E642D636F6C6F722C2023666666293B0A20202D2D74782D63702D6669656C643A20766172282D2D612D6669656C642D696E7075742D6261636B6772';
wwv_flow_imp.g_varchar2_table(3) := '6F756E642D636F6C6F722C20766172282D2D74782D63702D626729293B0A20202D2D74782D63702D6C696E653A20766172282D2D75742D636F6D706F6E656E742D626F726465722D636F6C6F722C207267626128302C20302C20302C202E313229293B0A';
wwv_flow_imp.g_varchar2_table(4) := '20202D2D74782D63702D746578743A20766172282D2D75742D636F6D706F6E656E742D746578742D64656661756C742D636F6C6F722C2023316632333333293B0A20202D2D74782D63702D6D757465643A20766172282D2D75742D636F6D706F6E656E74';
wwv_flow_imp.g_varchar2_table(5) := '2D746578742D6D757465642D636F6C6F722C2023366237303830293B0A20202D2D74782D63702D616363656E743A20766172282D2D75742D70616C657474652D7072696D6172792C2023333434326138293B0A7D0A0A2F2A207468652073656172636820';
wwv_flow_imp.g_varchar2_table(6) := '627574746F6E20696E2074686520726567696F6E202A2F0A2E74782D50616C6574746542746E207B0A2020646973706C61793A20666C65783B0A2020616C69676E2D6974656D733A2063656E7465723B0A20206761703A20313070783B0A202077696474';
wwv_flow_imp.g_varchar2_table(7) := '683A20313030253B0A20206D61782D77696474683A2034343070783B0A20206865696768743A20343070783B0A202070616464696E673A203020387078203020313270783B0A2020626F726465723A2031707820736F6C696420766172282D2D612D6669';
wwv_flow_imp.g_varchar2_table(8) := '656C642D696E7075742D626F726465722D636F6C6F722C20766172282D2D74782D63702D6C696E6529293B0A2020626F726465722D7261646975733A203870783B0A20206261636B67726F756E643A20766172282D2D74782D63702D6669656C64293B0A';
wwv_flow_imp.g_varchar2_table(9) := '2020636F6C6F723A20766172282D2D74782D63702D6D75746564293B0A2020666F6E743A20696E68657269743B0A2020666F6E742D73697A653A20313470783B0A2020746578742D616C69676E3A206C6566743B0A2020637572736F723A20706F696E74';
wwv_flow_imp.g_varchar2_table(10) := '65723B0A20207472616E736974696F6E3A20626F726465722D636F6C6F72202E3135732C20626F782D736861646F77202E3135733B0A7D0A2E74782D50616C6574746542746E3A686F766572207B20626F726465722D636F6C6F723A20636F6C6F722D6D';
wwv_flow_imp.g_varchar2_table(11) := '697828696E20737267622C20766172282D2D74782D63702D7465787429203330252C207472616E73706172656E74293B207D0A2E74782D50616C6574746542746E3A666F6375732D76697369626C65207B206F75746C696E653A2032707820736F6C6964';
wwv_flow_imp.g_varchar2_table(12) := '20766172282D2D74782D63702D616363656E74293B206F75746C696E652D6F66667365743A203170783B207D0A2E74782D50616C6574746542746E2D74657874207B20666C65783A20313B206D696E2D77696474683A20303B206F766572666C6F773A20';
wwv_flow_imp.g_varchar2_table(13) := '68696464656E3B20746578742D6F766572666C6F773A20656C6C69707369733B2077686974652D73706163653A206E6F777261703B207D0A2E74782D50616C65747465526567696F6E202E74782D50616C6574746542746E2D69636F6E2E6661207B2066';
wwv_flow_imp.g_varchar2_table(14) := '6F6E742D73697A653A20313470783B207D0A2E74782D50616C6574746542746E2D6B65792C0A2E74782D50616C65747465206B6264207B0A202070616464696E673A20317078203670783B0A2020626F726465723A2031707820736F6C69642076617228';
wwv_flow_imp.g_varchar2_table(15) := '2D2D74782D63702D6C696E65293B0A2020626F726465722D626F74746F6D2D77696474683A203270783B0A2020626F726465722D7261646975733A203570783B0A20206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C207661';
wwv_flow_imp.g_varchar2_table(16) := '72282D2D74782D63702D74657874292034252C20766172282D2D74782D63702D626729293B0A2020636F6C6F723A20766172282D2D74782D63702D6D75746564293B0A2020666F6E743A203630302031312E3570782F312E352075692D73616E732D7365';
wwv_flow_imp.g_varchar2_table(17) := '7269662C2073797374656D2D75692C202D6170706C652D73797374656D2C20225365676F65205549222C2073616E732D73657269663B0A202077686974652D73706163653A206E6F777261703B0A7D0A2E74782D50616C6574746542746E2D6B65795B68';
wwv_flow_imp.g_varchar2_table(18) := '696464656E5D207B20646973706C61793A206E6F6E653B207D0A0A2F2A20746865206469616C6F67202A2F0A68746D6C2E74782D50616C657474652D6C6F636B207B206F766572666C6F773A2068696464656E3B207D0A2E74782D50616C65747465207B';
wwv_flow_imp.g_varchar2_table(19) := '20706F736974696F6E3A2066697865643B20696E7365743A20303B207A2D696E6465783A20313130303B207D0A2E74782D50616C657474655B68696464656E5D207B20646973706C61793A206E6F6E653B207D0A2E74782D50616C657474652D6261636B';
wwv_flow_imp.g_varchar2_table(20) := '64726F70207B0A2020706F736974696F6E3A206162736F6C7574653B0A2020696E7365743A20303B0A20206261636B67726F756E643A20726762612831362C2031392C2033342C202E3432293B0A20206261636B64726F702D66696C7465723A20626C75';
wwv_flow_imp.g_varchar2_table(21) := '7228327078293B0A20206F7061636974793A20303B0A20207472616E736974696F6E3A206F706163697479202E31347320656173652D6F75743B0A7D0A2E74782D50616C657474652D6469616C6F67207B0A2020706F736974696F6E3A206162736F6C75';
wwv_flow_imp.g_varchar2_table(22) := '74653B0A20206C6566743A203530253B0A2020746F703A20313276683B0A2020646973706C61793A20666C65783B0A2020666C65782D646972656374696F6E3A20636F6C756D6E3B0A202077696474683A206D696E2836343070782C2063616C63283130';
wwv_flow_imp.g_varchar2_table(23) := '307677202D203332707829293B0A20206D61782D6865696768743A206D696E2835363070782C2063616C63283130307668202D2031327668202D203234707829293B0A20206F766572666C6F773A2068696464656E3B0A2020626F726465723A20317078';
wwv_flow_imp.g_varchar2_table(24) := '20736F6C696420766172282D2D74782D63702D6C696E65293B0A2020626F726465722D7261646975733A20313470783B0A20206261636B67726F756E643A20766172282D2D74782D63702D6267293B0A2020636F6C6F723A20766172282D2D74782D6370';
wwv_flow_imp.g_varchar2_table(25) := '2D74657874293B0A2020626F782D736861646F773A20302032347078203634707820726762612831362C2031392C2033342C202E3238292C2030203270782038707820726762612831362C2031392C2033342C202E3038293B0A20206F7061636974793A';
wwv_flow_imp.g_varchar2_table(26) := '20303B0A20207472616E73666F726D3A207472616E736C617465282D3530252C202D36707829207363616C65282E393835293B0A20207472616E736974696F6E3A206F706163697479202E31347320656173652D6F75742C207472616E73666F726D202E';
wwv_flow_imp.g_varchar2_table(27) := '31347320656173652D6F75743B0A7D0A2E74782D50616C657474652E69732D6F70656E202E74782D50616C657474652D6261636B64726F70207B206F7061636974793A20313B207D0A2E74782D50616C657474652E69732D6F70656E202E74782D50616C';
wwv_flow_imp.g_varchar2_table(28) := '657474652D6469616C6F67207B206F7061636974793A20313B207472616E73666F726D3A207472616E736C617465282D3530252C2030293B207D0A0A2E74782D50616C657474652D736561726368207B0A2020646973706C61793A20666C65783B0A2020';
wwv_flow_imp.g_varchar2_table(29) := '616C69676E2D6974656D733A2063656E7465723B0A20206761703A20313070783B0A202070616464696E673A203020313470783B0A2020626F726465722D626F74746F6D3A2031707820736F6C696420766172282D2D74782D63702D6C696E65293B0A7D';
wwv_flow_imp.g_varchar2_table(30) := '0A2E74782D50616C65747465202E74782D50616C657474652D73656172636849636F6E2E6661207B20666F6E742D73697A653A20313670783B20636F6C6F723A20766172282D2D74782D63702D6D75746564293B207D0A2E74782D50616C657474652D69';
wwv_flow_imp.g_varchar2_table(31) := '6E707574207B0A2020666C65783A20313B0A20206D696E2D77696474683A20303B0A20206865696768743A20353470783B0A202070616464696E673A20303B0A2020626F726465723A20303B0A20206261636B67726F756E643A207472616E7370617265';
wwv_flow_imp.g_varchar2_table(32) := '6E743B0A2020636F6C6F723A20766172282D2D74782D63702D74657874293B0A2020666F6E743A20696E68657269743B0A2020666F6E742D73697A653A20313770783B0A20206F75746C696E653A206E6F6E653B0A7D0A2E74782D50616C657474652D69';
wwv_flow_imp.g_varchar2_table(33) := '6E7075743A3A706C616365686F6C646572207B20636F6C6F723A20766172282D2D74782D63702D6D75746564293B207D0A2F2A20746865206469616C6F672069732074686520666F63757320636F6E7465787420616E6420746865206361726574207368';
wwv_flow_imp.g_varchar2_table(34) := '6F777320776865726520747970696E6720676F65733A206E6F206669656C642072696E672066726F6D20746865207468656D65202A2F0A2E74782D50616C65747465202E74782D50616C657474652D696E7075743A666F6375732C0A2E74782D50616C65';
wwv_flow_imp.g_varchar2_table(35) := '747465202E74782D50616C657474652D696E7075743A666F6375732D76697369626C65207B206F75746C696E653A206E6F6E653B20626F782D736861646F773A206E6F6E653B20626F726465723A20303B207D0A2E74782D50616C657474652D65736320';
wwv_flow_imp.g_varchar2_table(36) := '7B20637572736F723A20706F696E7465723B207D0A0A2E74782D50616C657474652D6C697374207B20666C65783A20313B206D696E2D6865696768743A20303B206F766572666C6F772D793A206175746F3B206F7665727363726F6C6C2D626568617669';
wwv_flow_imp.g_varchar2_table(37) := '6F723A20636F6E7461696E3B2070616464696E673A203670783B207D0A2E74782D50616C657474652D67726F7570202B202E74782D50616C657474652D67726F7570207B206D617267696E2D746F703A203470783B207D0A2E74782D50616C657474652D';
wwv_flow_imp.g_varchar2_table(38) := '67726F75704C6162656C207B2070616464696E673A20313070782031307078203470783B20636F6C6F723A20766172282D2D74782D63702D6D75746564293B20666F6E742D73697A653A20313270783B20666F6E742D7765696768743A203630303B207D';
wwv_flow_imp.g_varchar2_table(39) := '0A2E74782D50616C657474652D6974656D207B0A2020646973706C61793A20677269643B0A2020677269642D74656D706C6174652D636F6C756D6E733A2033327078206D696E6D617828302C2031667229206175746F3B0A2020616C69676E2D6974656D';
wwv_flow_imp.g_varchar2_table(40) := '733A2063656E7465723B0A20206761703A20313270783B0A20206D696E2D6865696768743A20343470783B0A202070616464696E673A2036707820313070783B0A2020626F726465722D7261646975733A203870783B0A2020637572736F723A20706F69';
wwv_flow_imp.g_varchar2_table(41) := '6E7465723B0A7D0A2E74782D50616C657474652D6974656D2E69732D616374697665207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D63702D616363656E7429203131252C207472616E737061';
wwv_flow_imp.g_varchar2_table(42) := '72656E74293B207D0A2E74782D50616C657474652D69636F6E207B0A2020646973706C61793A20677269643B0A2020706C6163652D6974656D733A2063656E7465723B0A202077696474683A20333270783B0A20206865696768743A20333270783B0A20';
wwv_flow_imp.g_varchar2_table(43) := '20626F726465722D7261646975733A203870783B0A20206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D63702D74657874292036252C207472616E73706172656E74293B0A2020636F6C6F723A2076';
wwv_flow_imp.g_varchar2_table(44) := '6172282D2D74782D63702D6D75746564293B0A7D0A2E74782D50616C657474652D6974656D2E69732D616374697665202E74782D50616C657474652D69636F6E207B206261636B67726F756E643A20766172282D2D74782D63702D616363656E74293B20';
wwv_flow_imp.g_varchar2_table(45) := '636F6C6F723A20236666663B207D0A2E74782D50616C65747465202E74782D50616C657474652D69636F6E202E6661207B20666F6E742D73697A653A20313570783B207D0A2E74782D50616C657474652D6D61696E207B20646973706C61793A20666C65';
wwv_flow_imp.g_varchar2_table(46) := '783B20666C65782D646972656374696F6E3A20636F6C756D6E3B206D696E2D77696474683A20303B207D0A2E74782D50616C657474652D7469746C65207B206F766572666C6F773A2068696464656E3B20746578742D6F766572666C6F773A20656C6C69';
wwv_flow_imp.g_varchar2_table(47) := '707369733B2077686974652D73706163653A206E6F777261703B20666F6E742D73697A653A20313470783B206C696E652D6865696768743A20312E343B207D0A2E74782D50616C657474652D7469746C65206D61726B207B206261636B67726F756E643A';
wwv_flow_imp.g_varchar2_table(48) := '207472616E73706172656E743B20636F6C6F723A20766172282D2D74782D63702D616363656E74293B20666F6E742D7765696768743A203730303B207D0A2E74782D50616C657474652D70617468207B20636F6C6F723A20766172282D2D74782D63702D';
wwv_flow_imp.g_varchar2_table(49) := '6D75746564293B207D0A2E74782D50616C657474652D64657363207B206F766572666C6F773A2068696464656E3B20746578742D6F766572666C6F773A20656C6C69707369733B2077686974652D73706163653A206E6F777261703B20636F6C6F723A20';
wwv_flow_imp.g_varchar2_table(50) := '766172282D2D74782D63702D6D75746564293B20666F6E742D73697A653A2031322E3570783B206C696E652D6865696768743A20312E343B207D0A2E74782D50616C657474652D6D657461207B20646973706C61793A20666C65783B20616C69676E2D69';
wwv_flow_imp.g_varchar2_table(51) := '74656D733A2063656E7465723B206761703A203670783B207D0A2E74782D50616C657474652D746167207B20636F6C6F723A20766172282D2D74782D63702D6D75746564293B20666F6E742D73697A653A20313270783B2077686974652D73706163653A';
wwv_flow_imp.g_varchar2_table(52) := '206E6F777261703B207D0A2E74782D50616C657474652D656D707479207B2070616464696E673A203238707820313670783B20636F6C6F723A20766172282D2D74782D63702D6D75746564293B20746578742D616C69676E3A2063656E7465723B207D0A';
wwv_flow_imp.g_varchar2_table(53) := '0A2E74782D50616C657474652D737461747573207B20706F736974696F6E3A206162736F6C7574653B2077696474683A203170783B206865696768743A203170783B206F766572666C6F773A2068696464656E3B20636C69703A20726563742830203020';
wwv_flow_imp.g_varchar2_table(54) := '302030293B2077686974652D73706163653A206E6F777261703B207D0A2E74782D50616C657474652D666F6F74207B0A2020646973706C61793A20666C65783B0A2020666C65782D777261703A20777261703B0A20206761703A20313670783B0A202070';
wwv_flow_imp.g_varchar2_table(55) := '616464696E673A2039707820313470783B0A2020626F726465722D746F703A2031707820736F6C696420766172282D2D74782D63702D6C696E65293B0A2020636F6C6F723A20766172282D2D74782D63702D6D75746564293B0A2020666F6E742D73697A';
wwv_flow_imp.g_varchar2_table(56) := '653A20313270783B0A7D0A0A406D6564696120286D61782D77696474683A20363430707829207B0A20202E74782D50616C657474652D6469616C6F67207B20746F703A203870783B206D61782D6865696768743A2063616C63283130307668202D203136';
wwv_flow_imp.g_varchar2_table(57) := '7078293B207D0A20202E74782D50616C657474652D666F6F74207B20646973706C61793A206E6F6E653B207D0A20202E74782D50616C657474652D746167207B20646973706C61793A206E6F6E653B207D0A7D0A0A406D65646961202870726566657273';
wwv_flow_imp.g_varchar2_table(58) := '2D726564756365642D6D6F74696F6E3A2072656475636529207B0A20202E74782D50616C657474652D6261636B64726F702C202E74782D50616C657474652D6469616C6F672C202E74782D50616C6574746542746E207B207472616E736974696F6E3A20';
wwv_flow_imp.g_varchar2_table(59) := '6E6F6E653B207D0A7D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6208010058861070)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_file_name=>'command-palette.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A0A202A20436F6D6D616E642050616C6574746520726567696F6E20706C75672D696E20666F72204F7261636C652041504558202854656368526576582C207777772E74656368726576782E636F6D290A202A0A202A2074656368726576782E636F6D';
wwv_flow_imp.g_varchar2_table(2) := '6D616E6450616C657474652E696E69742820726567696F6E49642C206F7074696F6E7320292069732063616C6C6564206279207468652072656E6465722070726F6365647572652E205468652070616C65747465206469616C6F67206973206275696C74';
wwv_flow_imp.g_varchar2_table(3) := '0A202A206F6E2066697273742075736520616E6420617070656E64656420746F203C626F64793E2E20436F6D6D616E647320636F6D652066726F6D3A0A202A20202074686520726567696F6E20736F757263652020206C6F616465642077697468207830';
wwv_flow_imp.g_varchar2_table(4) := '313D4C495354207468652066697273742074696D65207468652070616C65747465206F70656E732028726566726573682829206C6F616473207468656D20616761696E290A202A202020616464436F6D6D616E6473282920202020202020636F6D6D616E';
wwv_flow_imp.g_varchar2_table(5) := '64732061646465642077697468204A6176615363726970742C207768696368206D61792072756E20612066756E6374696F6E0A202A202020746865204E617669676174696F6E204D656E7520726561642066726F6D207468652072656E6465726564206D';
wwv_flow_imp.g_varchar2_table(6) := '656E75202823745F547265654E6176292C20736F20636F6E646974696F6E7320616E6420617574686F72697A6174696F6E20616C7265616479206170706C790A202A2020207061676520616374696F6E732020202020202020746865206C6162656C6C65';
wwv_flow_imp.g_varchar2_table(7) := '6420617065782E616374696F6E73206F662074686520706167650A202A0A202A20436F6D6D616E643A207B20743A207469746C652C20706174682C206C3A206C696E6B2C20673A2067726F75702C20693A2069636F6E2C20643A20646573637269707469';
wwv_flow_imp.g_varchar2_table(8) := '6F6E2C206B3A206B6579776F7264732C20733A2073686F72746375742C20763A2076616C75652C0A202A202020202020202020202020613A20617065782E616374696F6E73206E616D652C20666E3A2066756E6374696F6E207D0A202A0A202A20617065';
wwv_flow_imp.g_varchar2_table(9) := '782E726567696F6E2820696420292E6F70656E282071756572792029202F20636C6F73652829202F20746F67676C652829202F20726566726573682829202F20616464436F6D6D616E64732820636F6D6D616E647320290A202A204576656E7473206F6E';
wwv_flow_imp.g_varchar2_table(10) := '2074686520726567696F6E3A2074782D636F6D6D616E6470616C657474652D6F70656E2C2074782D636F6D6D616E6470616C657474652D636C6F73652C0A202A20202074782D636F6D6D616E6470616C657474652D73656C656374207B207469746C652C';
wwv_flow_imp.g_varchar2_table(11) := '2076616C75652C2067726F75702C206C696E6B2C20616374696F6E207D0A202A2F0A282066756E6374696F6E2820242C20617065782029207B0A202020202275736520737472696374223B0A0A20202020636F6E7374206E73203D2077696E646F772E74';
wwv_flow_imp.g_varchar2_table(12) := '65636872657678203D2077696E646F772E7465636872657678207C7C207B7D2C0A202020202020202049535F4D4143203D202F4D61637C6950686F6E657C695061642F2E7465737428206E6176696761746F722E706C6174666F726D207C7C206E617669';
wwv_flow_imp.g_varchar2_table(13) := '6761746F722E757365724167656E7420292C0A2020202020202020574F52445F5354415254203D202F5B5C735C2D5F2F2E3A282CE280BA5D2F3B0A202020206C6574206F70656E50616C65747465203D206E756C6C3B0A0A2020202066756E6374696F6E';
wwv_flow_imp.g_varchar2_table(14) := '20656C28207461672C20636C732C20746578742029207B0A2020202020202020636F6E73742065203D20646F63756D656E742E637265617465456C656D656E74282074616720293B0A20202020202020206966202820636C732029207B20652E636C6173';
wwv_flow_imp.g_varchar2_table(15) := '734E616D65203D20636C733B207D0A202020202020202069662028207465787420213D206E756C6C2029207B20652E74657874436F6E74656E74203D20746578743B207D0A202020202020202072657475726E20653B0A202020207D0A0A202020206675';
wwv_flow_imp.g_varchar2_table(16) := '6E6374696F6E206E6F726D2820732029207B2072657475726E2073203D3D206E756C6C203F202222203A20537472696E6728207320292E746F4C6F7765724361736528293B207D0A0A202020202F2F20224374726C2B53686966742B4B22202D3E207B20';
wwv_flow_imp.g_varchar2_table(17) := '6374726C2C2073686966742C20616C742C206B65793A20226B22207D3B20222F22202D3E207B206B65793A20222F22207D0A2020202066756E6374696F6E20706172736553686F72746375742820746578742029207B0A20202020202020206966202820';
wwv_flow_imp.g_varchar2_table(18) := '2174657874207C7C2021537472696E6728207465787420292E7472696D28292029207B2072657475726E206E756C6C3B207D0A2020202020202020636F6E7374207363203D207B206374726C3A2066616C73652C2073686966743A2066616C73652C2061';
wwv_flow_imp.g_varchar2_table(19) := '6C743A2066616C73652C206B65793A202222207D3B0A2020202020202020537472696E6728207465787420292E73706C697428202F5C2B283F2124292F20292E6D6170282070203D3E20702E7472696D282920292E666F7245616368282070203D3E207B';
wwv_flow_imp.g_varchar2_table(20) := '0A202020202020202020202020636F6E7374206C203D20702E746F4C6F7765724361736528293B0A20202020202020202020202069662028205B20226374726C222C2022636F6E74726F6C222C2022636D64222C2022636F6D6D616E64222C20226D6574';
wwv_flow_imp.g_varchar2_table(21) := '61222C20226D6F6422205D2E696E636C7564657328206C20292029207B2073632E6374726C203D20747275653B207D0A202020202020202020202020656C73652069662028206C203D3D3D20227368696674222029207B2073632E7368696674203D2074';
wwv_flow_imp.g_varchar2_table(22) := '7275653B207D0A202020202020202020202020656C73652069662028206C203D3D3D2022616C7422207C7C206C203D3D3D20226F7074696F6E222029207B2073632E616C74203D20747275653B207D0A202020202020202020202020656C7365207B2073';
wwv_flow_imp.g_varchar2_table(23) := '632E6B6579203D206C3B207D0A20202020202020207D20293B0A202020202020202072657475726E2073632E6B6579203F207363203A206E756C6C3B0A202020207D0A0A2020202066756E6374696F6E206D61746368657353686F727463757428207363';
wwv_flow_imp.g_varchar2_table(24) := '2C20652029207B0A2020202020202020636F6E7374206D6F64203D2049535F4D4143203F20652E6D6574614B6579207C7C20652E6374726C4B6579203A20652E6374726C4B65792026262021652E6D6574614B65793B0A20202020202020206966202820';
wwv_flow_imp.g_varchar2_table(25) := '73632E6374726C20213D3D206D6F64207C7C2073632E616C7420213D3D20652E616C744B65792029207B2072657475726E2066616C73653B207D0A20202020202020202F2F2053686966742069732070617274206F66206C6574746572732C2064696769';
wwv_flow_imp.g_varchar2_table(26) := '747320616E64206E616D6564206B6579733B20666F722073796D626F6C732073756368206173202F206F72203F20746865206C61796F757420646563696465730A202020202020202069662028202F5E5B612D7A302D395D242F2E74657374282073632E';
wwv_flow_imp.g_varchar2_table(27) := '6B65792029207C7C2073632E6B65792E6C656E677468203E20312029207B0A202020202020202020202020696620282073632E736869667420213D3D20652E73686966744B65792029207B2072657475726E2066616C73653B207D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(28) := '2020202072657475726E206E6F726D2820652E6B65792029203D3D3D2073632E6B6579207C7C206E6F726D2820652E636F64652029203D3D3D20226B657922202B2073632E6B6579207C7C206E6F726D2820652E636F64652029203D3D3D202264696769';
wwv_flow_imp.g_varchar2_table(29) := '7422202B2073632E6B65793B0A20202020202020207D0A202020202020202072657475726E20652E6B6579203D3D3D2073632E6B65793B0A202020207D0A0A2020202066756E6374696F6E2073686F72746375744C6162656C282073632029207B0A2020';
wwv_flow_imp.g_varchar2_table(30) := '202020202020636F6E73742070203D205B5D3B0A2020202020202020696620282073632E6374726C2029207B20702E70757368282049535F4D4143203F2022E28C9822203A20224374726C2220293B207D0A2020202020202020696620282073632E616C';
wwv_flow_imp.g_varchar2_table(31) := '742029207B20702E70757368282049535F4D4143203F2022E28CA522203A2022416C742220293B207D0A2020202020202020696620282073632E73686966742029207B20702E70757368282049535F4D4143203F2022E287A722203A2022536869667422';
wwv_flow_imp.g_varchar2_table(32) := '20293B207D0A2020202020202020702E70757368282073632E6B65792E6C656E677468203D3D3D2031203F2073632E6B65792E746F5570706572436173652829203A2073632E6B65792E63686172417428203020292E746F557070657243617365282920';
wwv_flow_imp.g_varchar2_table(33) := '2B2073632E6B65792E736C696365282031202920293B0A202020202020202072657475726E2049535F4D4143203F20702E6A6F696E282022222029203A20702E6A6F696E282022202220293B0A202020207D0A0A2020202066756E6374696F6E20697345';
wwv_flow_imp.g_varchar2_table(34) := '64697461626C652820742029207B0A202020202020202072657475726E2074202626202820742E6973436F6E74656E744564697461626C65207C7C202F5E28494E5055547C54455854415245417C53454C45435429242F2E746573742820742E7461674E';
wwv_flow_imp.g_varchar2_table(35) := '616D65202920293B0A202020207D0A0A202020202F2F20576865726520746865206C657474657273206F6620712061707065617220696E20746578742C20626573742066697273743A206120737562737472696E6720286174206120776F726420737461';
wwv_flow_imp.g_varchar2_table(36) := '727420697320626574746572292C20746865206669727374206C6574746572730A202020202F2F206F6620776F7264732028226B622220696E204B616E62616E20426F617264292C207468656E20746865206C65747465727320696E206F726465722C20';
wwv_flow_imp.g_varchar2_table(37) := '7374617274696E672066726F6D2077686963686576657220706F736974696F6E20666974732074696768746573742E0A2020202066756E6374696F6E2066696E64496E2820712C20746578742029207B0A2020202020202020636F6E73742074203D206E';
wwv_flow_imp.g_varchar2_table(38) := '6F726D28207465787420292C206174203D20742E696E6465784F6628207120293B0A202020202020202069662028206174203E3D20302029207B0A202020202020202020202020636F6E7374207374617274203D206174203D3D3D2030207C7C20574F52';
wwv_flow_imp.g_varchar2_table(39) := '445F53544152542E746573742820745B206174202D2031205D20293B0A20202020202020202020202072657475726E207B2073636F72653A203230202B2028206174203D3D3D2030203F203130203A20302029202B2028207374617274203F2036203A20';
wwv_flow_imp.g_varchar2_table(40) := '302029202D204D6174682E6D696E282061742C2031302029202A20302E322C206964783A2041727261792E66726F6D28207B206C656E6774683A20712E6C656E677468207D2C2028205F2C20692029203D3E206174202B20692029207D3B0A2020202020';
wwv_flow_imp.g_varchar2_table(41) := '2020207D0A2020202020202020636F6E737420696E697469616C73203D205B5D3B0A20202020202020206C6574206B203D20303B0A2020202020202020666F722028206C65742069203D20303B2069203C20742E6C656E677468202626206B203C20712E';
wwv_flow_imp.g_varchar2_table(42) := '6C656E6774683B20692B2B2029207B0A2020202020202020202020206966202820282069203D3D3D2030207C7C20574F52445F53544152542E746573742820745B2069202D2031205D2029202920262620745B2069205D203D3D3D20715B206B205D2029';
wwv_flow_imp.g_varchar2_table(43) := '207B20696E697469616C732E7075736828206920293B206B2B2B3B207D0A20202020202020207D0A202020202020202069662028206B203D3D3D20712E6C656E67746820262620712E6C656E677468203E20312029207B2072657475726E207B2073636F';
wwv_flow_imp.g_varchar2_table(44) := '72653A203138202B20712E6C656E677468202A20322C206964783A20696E697469616C73207D3B207D0A0A20202020202020202F2F206C65747465727320737072656164206F7574206861766520746F207374617920636C6F736520746F676574686572';
wwv_flow_imp.g_varchar2_table(45) := '3B2074776F206C65747465727320616C736F206861766520746F207374617274206120776F7264202822646D2220696E2044656D6F290A20202020202020206C65742062657374203D206E756C6C3B0A2020202020202020666F722028206C6574207320';
wwv_flow_imp.g_varchar2_table(46) := '3D20742E696E6465784F662820715B2030205D20293B2073203E3D20303B2073203D20742E696E6465784F662820715B2030205D2C2073202B203120292029207B0A202020202020202020202020636F6E737420696478203D205B5D3B0A202020202020';
wwv_flow_imp.g_varchar2_table(47) := '2020202020206C6574206A203D20302C2073636F7265203D20302C2070726576203D202D323B0A202020202020202020202020666F722028206C65742069203D20733B2069203C20742E6C656E677468202626206A203C20712E6C656E6774683B20692B';
wwv_flow_imp.g_varchar2_table(48) := '2B2029207B0A202020202020202020202020202020206966202820745B2069205D203D3D3D20715B206A205D2029207B0A202020202020202020202020202020202020202073636F7265202B3D20282069203D3D3D2070726576202B2031203F2033203A';
wwv_flow_imp.g_varchar2_table(49) := '20312029202B20282069203D3D3D2030207C7C20574F52445F53544152542E746573742820745B2069202D2031205D2029203F2032203A203020293B0A20202020202020202020202020202020202020206964782E7075736828206920293B0A20202020';
wwv_flow_imp.g_varchar2_table(50) := '2020202020202020202020202020202070726576203D20693B0A20202020202020202020202020202020202020206A2B2B3B0A202020202020202020202020202020207D0A2020202020202020202020207D0A2020202020202020202020206966202820';
wwv_flow_imp.g_varchar2_table(51) := '6A203C20712E6C656E6774682029207B20627265616B3B207D202F2F206C61746572207374617274732063616E6E6F7420666974206569746865720A202020202020202020202020636F6E7374207370616E203D206964785B206964782E6C656E677468';
wwv_flow_imp.g_varchar2_table(52) := '202D2031205D202D206964785B2030205D3B0A20202020202020202020202069662028207370616E203E20712E6C656E677468202A20342029207B20636F6E74696E75653B207D0A2020202020202020202020206966202820712E6C656E677468203C20';
wwv_flow_imp.g_varchar2_table(53) := '332026262028207370616E203E2033207C7C202128206964785B2030205D203D3D3D2030207C7C20574F52445F53544152542E746573742820745B206964785B2030205D202D2031205D2029202920292029207B20636F6E74696E75653B207D0A202020';
wwv_flow_imp.g_varchar2_table(54) := '20202020202020202073636F7265202D3D207370616E202A20302E31353B0A20202020202020202020202069662028202162657374207C7C2073636F7265203E20626573742E73636F72652029207B2062657374203D207B2073636F72652C2069647820';
wwv_flow_imp.g_varchar2_table(55) := '7D3B207D0A20202020202020207D0A202020202020202072657475726E20626573743B0A202020207D0A0A2020202066756E6374696F6E206C6162656C2820636D642029207B2072657475726E20636D642E70617468203F20636D642E70617468202B20';
wwv_flow_imp.g_varchar2_table(56) := '2220E280BA2022202B20636D642E74203A20636D642E743B207D0A0A202020202F2F20657665727920776F7264206F66207468652071756572792068617320746F206D6174636820746865206C6162656C20287061746820616E64207469746C65292C20';
wwv_flow_imp.g_varchar2_table(57) := '6F7220656C7365207468652067726F75702C206465736372697074696F6E206F72206B6579776F7264733B0A202020202F2F206D61726B732061726520706F736974696F6E7320696E20746865206C6162656C0A2020202066756E6374696F6E2072616E';
wwv_flow_imp.g_varchar2_table(58) := '6B2820636D642C20746F6B656E732029207B0A20202020202020206C657420746F74616C203D20303B0A2020202020202020636F6E7374206D61726B73203D206E65772053657428293B0A2020202020202020666F72202820636F6E737420746F6B206F';
wwv_flow_imp.g_varchar2_table(59) := '6620746F6B656E732029207B0A202020202020202020202020636F6E7374206D203D2066696E64496E2820746F6B2C206C6162656C2820636D64202920293B0A20202020202020202020202069662028206D2029207B0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(60) := '202020746F74616C202B3D206D2E73636F7265202A20323B0A202020202020202020202020202020206D2E6964782E666F7245616368282069203D3E206D61726B732E616464282069202920293B0A20202020202020202020202020202020636F6E7469';
wwv_flow_imp.g_varchar2_table(61) := '6E75653B0A2020202020202020202020207D0A20202020202020202020202069662028206E6F726D28205B20636D642E672C20636D642E642C20636D642E6B205D2E6A6F696E2820222022202920292E696E636C756465732820746F6B20292029207B0A';
wwv_flow_imp.g_varchar2_table(62) := '20202020202020202020202020202020746F74616C202B3D20383B0A20202020202020202020202020202020636F6E74696E75653B0A2020202020202020202020207D0A20202020202020202020202072657475726E206E756C6C3B0A20202020202020';
wwv_flow_imp.g_varchar2_table(63) := '207D0A202020202020202072657475726E207B2073636F72653A20746F74616C2C206D61726B73207D3B0A202020207D0A0A2020202066756E6374696F6E20636F6D6D616E642820632C207372632029207B0A2020202020202020636F6E737420636D64';
wwv_flow_imp.g_varchar2_table(64) := '203D207B0A202020202020202020202020743A20632E7420213D206E756C6C203F20537472696E672820632E742029203A20632E7469746C6520213D206E756C6C203F20537472696E672820632E7469746C652029203A2022222C0A2020202020202020';
wwv_flow_imp.g_varchar2_table(65) := '20202020706174683A20632E70617468207C7C2022222C0A2020202020202020202020206C3A20632E6C207C7C20632E6C696E6B207C7C2022222C0A202020202020202020202020673A20632E67207C7C20632E67726F7570207C7C2022222C0A202020';
wwv_flow_imp.g_varchar2_table(66) := '202020202020202020693A20632E69207C7C20632E69636F6E207C7C2022222C0A202020202020202020202020643A20632E64207C7C20632E6465736372697074696F6E207C7C2022222C0A2020202020202020202020206B3A20632E6B207C7C20632E';
wwv_flow_imp.g_varchar2_table(67) := '6B6579776F726473207C7C2022222C0A202020202020202020202020733A20632E73207C7C20632E73686F7274637574207C7C2022222C0A202020202020202020202020763A20632E7620213D206E756C6C203F20632E76203A20632E76616C75652C0A';
wwv_flow_imp.g_varchar2_table(68) := '202020202020202020202020613A20632E61207C7C202820747970656F6620632E616374696F6E203D3D3D2022737472696E6722203F20632E616374696F6E203A20222220292C0A202020202020202020202020666E3A20747970656F6620632E616374';
wwv_flow_imp.g_varchar2_table(69) := '696F6E203D3D3D202266756E6374696F6E22203F20632E616374696F6E203A206E756C6C2C0A2020202020202020202020207372630A20202020202020207D3B0A2020202020202020636D642E6B6579203D205B20636D642E672C20636D642E70617468';
wwv_flow_imp.g_varchar2_table(70) := '2C20636D642E742C20636D642E6C207C7C20636D642E61207C7C202820636D642E7620213D206E756C6C203F20636D642E76203A2022222029205D2E6A6F696E2820227C2220293B0A202020202020202072657475726E20636D643B0A202020207D0A0A';
wwv_flow_imp.g_varchar2_table(71) := '202020202F2F20746865206170702773206E617669676174696F6E206D656E752061732072656E646572656420666F72207468697320757365720A2020202066756E6374696F6E206E6176436F6D6D616E64732829207B0A2020202020202020636F6E73';
wwv_flow_imp.g_varchar2_table(72) := '74206F7574203D205B5D2C207365656E203D206E65772053657428293B0A2020202020202020636F6E737420616464203D2028206C6162656C2C206C696E6B2C2069636F6E2C20706174682029203D3E207B0A2020202020202020202020206C6162656C';
wwv_flow_imp.g_varchar2_table(73) := '203D2028206C6162656C207C7C20222220292E7472696D28293B0A2020202020202020202020206966202820216C6162656C207C7C20216C696E6B207C7C206C696E6B203D3D3D20222322207C7C202F5E736570617261746F72242F692E746573742820';
wwv_flow_imp.g_varchar2_table(74) := '6C696E6B2029207C7C207365656E2E686173282070617468202B206C6162656C202B206C696E6B20292029207B2072657475726E3B207D0A2020202020202020202020207365656E2E616464282070617468202B206C6162656C202B206C696E6B20293B';
wwv_flow_imp.g_varchar2_table(75) := '0A2020202020202020202020206F75742E707573682820636F6D6D616E6428207B20743A206C6162656C2C206C3A206C696E6B2C20693A2069636F6E207C7C202266612D66696C652D6F222C20706174682C20673A2022506167657322207D2C20226E61';
wwv_flow_imp.g_varchar2_table(76) := '7622202920293B0A20202020202020207D3B0A2020202020202020636F6E73742074726565203D202428202223745F547265654E61762220293B0A20202020202020206966202820747265652E6C656E6774682029207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(77) := '747279207B0A20202020202020202020202020202020636F6E73742061203D20747265652E74726565566965772820226765744E6F6465416461707465722220293B0A20202020202020202020202020202020636F6E73742077616C6B203D2028206E2C';
wwv_flow_imp.g_varchar2_table(78) := '20706174682029203D3E207B0A2020202020202020202020202020202020202020666F722028206C65742069203D20303B2069203C20612E6368696C64436F756E7428206E20293B20692B2B2029207B0A20202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(79) := '2020202020636F6E73742063203D20612E6368696C6428206E2C206920292C206C6162656C203D20612E6765744C6162656C28206320293B0A20202020202020202020202020202020202020202020202061646428206C6162656C2C20632E6C696E6B20';
wwv_flow_imp.g_varchar2_table(80) := '7C7C202820612E6765744C696E6B203F20612E6765744C696E6B2820632029203A20222220292C20632E69636F6E207C7C202820612E67657449636F6E203F20612E67657449636F6E2820632029203A20222220292C20706174682E6A6F696E28202220';
wwv_flow_imp.g_varchar2_table(81) := 'E280BA2022202920293B0A2020202020202020202020202020202020202020202020206966202820612E6861734368696C6472656E28206320292029207B2077616C6B2820632C20706174682E636F6E63617428206C6162656C202920293B207D0A2020';
wwv_flow_imp.g_varchar2_table(82) := '2020202020202020202020202020202020207D0A202020202020202020202020202020207D3B0A2020202020202020202020202020202077616C6B2820612E726F6F7428292C205B5D20293B0A2020202020202020202020207D20636174636820282065';
wwv_flow_imp.g_varchar2_table(83) := '2029207B0A202020202020202020202020202020202F2F206E6F7420612074726565566965772028796574293A207265616420746865206C696E6B732062656C6F770A2020202020202020202020207D0A20202020202020207D0A202020202020202069';
wwv_flow_imp.g_varchar2_table(84) := '66202820216F75742E6C656E6774682029207B0A202020202020202020202020646F63756D656E742E717565727953656C6563746F72416C6C28202223745F547265654E617620615B687265665D2C202E742D4865616465722D6E617620615B68726566';
wwv_flow_imp.g_varchar2_table(85) := '5D2220292E666F724561636828206C696E6B203D3E2061646428206C696E6B2E74657874436F6E74656E742C206C696E6B2E676574417474726962757465282022687265662220292C2022222C202222202920293B0A20202020202020207D0A20202020';
wwv_flow_imp.g_varchar2_table(86) := '2020202072657475726E206F75743B0A202020207D0A0A2020202066756E6374696F6E20616374696F6E436F6D6D616E64732829207B0A2020202020202020636F6E7374206F7574203D205B5D3B0A20202020202020202820617065782E616374696F6E';
wwv_flow_imp.g_varchar2_table(87) := '732E6C697374203F20617065782E616374696F6E732E6C6973742829203A205B5D20292E666F724561636828206974656D203D3E207B0A202020202020202020202020636F6E737420616374696F6E203D20617065782E616374696F6E732E6C6F6F6B75';
wwv_flow_imp.g_varchar2_table(88) := '7028206974656D2E6E616D6520293B0A202020202020202020202020696620282021616374696F6E207C7C20216974656D2E6C6162656C207C7C20616374696F6E2E68696465207C7C20616374696F6E2E64697361626C6564207C7C202F5E74782D2F2E';
wwv_flow_imp.g_varchar2_table(89) := '7465737428206974656D2E6E616D6520292029207B2072657475726E3B207D0A2020202020202020202020206F75742E707573682820636F6D6D616E6428207B20743A206974656D2E6C6162656C2C20613A206974656D2E6E616D652C20693A20616374';
wwv_flow_imp.g_varchar2_table(90) := '696F6E2E69636F6E207C7C202266612D626F6C74222C20733A20616374696F6E2E73686F7274637574207C7C2022222C20673A2022416374696F6E73206F6E2074686973207061676522207D2C2022616374696F6E7322202920293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(91) := '207D20293B0A202020202020202072657475726E206F75743B0A202020207D0A0A20202020636C6173732050616C65747465207B0A2020202020202020636F6E7374727563746F722820726567696F6E49642C206F7074696F6E732029207B0A20202020';
wwv_flow_imp.g_varchar2_table(92) := '2020202020202020746869732E726567696F6E4964203D20726567696F6E49643B0A202020202020202020202020746869732E6F203D206F7074696F6E733B0A202020202020202020202020746869732E736F7572636573203D20537472696E6728206F';
wwv_flow_imp.g_varchar2_table(93) := '7074696F6E732E736F7572636573207C7C20222220292E73706C69742820223A2220293B0A202020202020202020202020746869732E73686F7274637574203D20706172736553686F727463757428206F7074696F6E732E73686F727463757420293B0A';
wwv_flow_imp.g_varchar2_table(94) := '202020202020202020202020746869732E6A73436F6D6D616E6473203D205B5D3B0A202020202020202020202020746869732E736572766572203D206E756C6C3B0A202020202020202020202020746869732E6974656D73203D205B5D3B0A2020202020';
wwv_flow_imp.g_varchar2_table(95) := '20202020202020746869732E616374697665203D202D313B0A202020202020202020202020746869732E69734F70656E203D2066616C73653B0A202020202020202020202020746869732E73746F72654B6579203D202274782D70616C657474653A2220';
wwv_flow_imp.g_varchar2_table(96) := '2B206F7074696F6E732E6170704964202B20223A22202B20726567696F6E49643B0A0A202020202020202020202020636F6E73742062746E203D20646F63756D656E742E717565727953656C6563746F722820222322202B204353532E65736361706528';
wwv_flow_imp.g_varchar2_table(97) := '20726567696F6E49642029202B20225F70616C65747465202E74782D50616C6574746542746E2220293B0A202020202020202020202020696620282062746E2029207B0A20202020202020202020202020202020636F6E7374206B6579203D2062746E2E';
wwv_flow_imp.g_varchar2_table(98) := '717565727953656C6563746F722820222E74782D50616C6574746542746E2D6B65792220293B0A202020202020202020202020202020206966202820746869732E73686F7274637574202626206B65792029207B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(99) := '20202020206B65792E74657874436F6E74656E74203D2073686F72746375744C6162656C2820746869732E73686F727463757420293B0A20202020202020202020202020202020202020206B65792E68696464656E203D2066616C73653B0A2020202020';
wwv_flow_imp.g_varchar2_table(100) := '20202020202020202020202020202062746E2E736574417474726962757465282022617269612D6B657973686F727463757473222C202820746869732E73686F72746375742E6374726C203F20282049535F4D4143203F20224D6574612B22203A202243';
wwv_flow_imp.g_varchar2_table(101) := '6F6E74726F6C2B222029203A2022222029202B202820746869732E73686F72746375742E7368696674203F202253686966742B22203A2022222029202B20746869732E73686F72746375742E6B65792E746F557070657243617365282920293B0A202020';
wwv_flow_imp.g_varchar2_table(102) := '202020202020202020202020207D0A2020202020202020202020202020202062746E2E6164644576656E744C697374656E6572282022636C69636B222C202829203D3E20746869732E6F70656E282920293B0A2020202020202020202020207D0A202020';
wwv_flow_imp.g_varchar2_table(103) := '2020202020202020206966202820746869732E73686F72746375742029207B0A20202020202020202020202020202020646F63756D656E742E6164644576656E744C697374656E65722820226B6579646F776E222C2065203D3E207B0A20202020202020';
wwv_flow_imp.g_varchar2_table(104) := '202020202020202020202020206966202820652E64656661756C7450726576656E746564207C7C20652E6973436F6D706F73696E67207C7C20216D61746368657353686F72746375742820746869732E73686F72746375742C206520292029207B207265';
wwv_flow_imp.g_varchar2_table(105) := '7475726E3B207D0A20202020202020202020202020202020202020202F2F20612073696E676C65206B65792073756368206173202F206973207479706564207465787420696E73696465206669656C64732C207468652070616C657474652773206F776E';
wwv_flow_imp.g_varchar2_table(106) := '2073656172636820626F7820696E636C756465640A2020202020202020202020202020202020202020696620282021746869732E73686F72746375742E6374726C2026262021746869732E73686F72746375742E616C742026262069734564697461626C';
wwv_flow_imp.g_varchar2_table(107) := '652820652E74617267657420292029207B2072657475726E3B207D0A2020202020202020202020202020202020202020652E70726576656E7444656661756C7428293B0A2020202020202020202020202020202020202020746869732E746F67676C6528';
wwv_flow_imp.g_varchar2_table(108) := '293B0A202020202020202020202020202020207D20293B0A2020202020202020202020207D0A20202020202020207D0A0A20202020202020206275696C642829207B0A202020202020202020202020636F6E7374206964203D20746869732E726567696F';
wwv_flow_imp.g_varchar2_table(109) := '6E4964202B20225F6469616C6F67223B0A202020202020202020202020746869732E726F6F74203D20656C282022646976222C202274782D50616C657474652220293B0A202020202020202020202020746869732E726F6F742E68696464656E203D2074';
wwv_flow_imp.g_varchar2_table(110) := '7275653B0A202020202020202020202020636F6E7374206261636B64726F70203D20656C282022646976222C202274782D50616C657474652D6261636B64726F702220293B0A2020202020202020202020206261636B64726F702E6164644576656E744C';
wwv_flow_imp.g_varchar2_table(111) := '697374656E65722820226D6F757365646F776E222C202829203D3E20746869732E636C6F7365282920293B0A0A202020202020202020202020746869732E6469616C6F67203D20656C282022646976222C202274782D50616C657474652D6469616C6F67';
wwv_flow_imp.g_varchar2_table(112) := '2220293B0A202020202020202020202020746869732E6469616C6F672E6964203D2069643B0A202020202020202020202020746869732E6469616C6F672E736574417474726962757465282022726F6C65222C20226469616C6F672220293B0A20202020';
wwv_flow_imp.g_varchar2_table(113) := '2020202020202020746869732E6469616C6F672E736574417474726962757465282022617269612D6D6F64616C222C2022747275652220293B0A202020202020202020202020746869732E6469616C6F672E736574417474726962757465282022617269';
wwv_flow_imp.g_varchar2_table(114) := '612D6C6162656C222C20746869732E6F2E7469746C65207C7C2022436F6D6D616E642070616C657474652220293B0A0A202020202020202020202020636F6E737420626172203D20656C282022646976222C202274782D50616C657474652D7365617263';
wwv_flow_imp.g_varchar2_table(115) := '682220292C0A2020202020202020202020202020202069636F6E203D20656C2820227370616E222C202274782D50616C657474652D73656172636849636F6E2066612066612D7365617263682220292C0A20202020202020202020202020202020657363';
wwv_flow_imp.g_varchar2_table(116) := '203D20656C2820226B6264222C202274782D50616C657474652D657363222C20224573632220293B0A20202020202020202020202069636F6E2E736574417474726962757465282022617269612D68696464656E222C2022747275652220293B0A202020';
wwv_flow_imp.g_varchar2_table(117) := '202020202020202020746869732E696E707574203D20656C282022696E707574222C202274782D50616C657474652D696E7075742220293B0A202020202020202020202020746869732E696E7075742E74797065203D202274657874223B0A2020202020';
wwv_flow_imp.g_varchar2_table(118) := '20202020202020746869732E696E7075742E706C616365686F6C646572203D20746869732E6F2E706C616365686F6C646572207C7C2022536561726368206F72206A756D7020746F2E2E2E223B0A202020202020202020202020746869732E696E707574';
wwv_flow_imp.g_varchar2_table(119) := '2E6175746F636F6D706C657465203D20226F6666223B0A202020202020202020202020746869732E696E7075742E7370656C6C636865636B203D2066616C73653B0A202020202020202020202020746869732E696E7075742E7365744174747269627574';
wwv_flow_imp.g_varchar2_table(120) := '65282022726F6C65222C2022636F6D626F626F782220293B0A202020202020202020202020746869732E696E7075742E736574417474726962757465282022617269612D657870616E646564222C2022747275652220293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(121) := '20746869732E696E7075742E736574417474726962757465282022617269612D636F6E74726F6C73222C206964202B20225F6C6973742220293B0A202020202020202020202020746869732E696E7075742E736574417474726962757465282022617269';
wwv_flow_imp.g_varchar2_table(122) := '612D6175746F636F6D706C657465222C20226C6973742220293B0A202020202020202020202020746869732E696E7075742E736574417474726962757465282022617269612D6C6162656C222C20746869732E6F2E706C616365686F6C646572207C7C20';
wwv_flow_imp.g_varchar2_table(123) := '2253656172636820636F6D6D616E64732220293B0A202020202020202020202020746869732E696E7075742E6164644576656E744C697374656E6572282022696E707574222C202829203D3E20746869732E72656E646572282920293B0A202020202020';
wwv_flow_imp.g_varchar2_table(124) := '202020202020746869732E696E7075742E6164644576656E744C697374656E65722820226B6579646F776E222C2065203D3E20746869732E6F6E4B6579282065202920293B0A2020202020202020202020206573632E7365744174747269627574652820';
wwv_flow_imp.g_varchar2_table(125) := '22617269612D68696464656E222C2022747275652220293B0A2020202020202020202020206573632E6164644576656E744C697374656E6572282022636C69636B222C202829203D3E20746869732E636C6F7365282920293B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(126) := '20206261722E617070656E64282069636F6E2C20746869732E696E7075742C2065736320293B0A0A202020202020202020202020746869732E6C697374203D20656C282022646976222C202274782D50616C657474652D6C6973742220293B0A20202020';
wwv_flow_imp.g_varchar2_table(127) := '2020202020202020746869732E6C6973742E6964203D206964202B20225F6C697374223B0A202020202020202020202020746869732E6C6973742E736574417474726962757465282022726F6C65222C20226C697374626F782220293B0A202020202020';
wwv_flow_imp.g_varchar2_table(128) := '202020202020746869732E6C6973742E736574417474726962757465282022617269612D6C6162656C222C2022436F6D6D616E64732220293B0A202020202020202020202020746869732E6C6973742E6164644576656E744C697374656E65722820226D';
wwv_flow_imp.g_varchar2_table(129) := '6F7573656D6F7665222C2065203D3E207B0A20202020202020202020202020202020636F6E7374206F7074203D20652E7461726765742E636C6F736573742820222E74782D50616C657474652D6974656D2220293B0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(130) := '202069662028206F7074202626202820652E6D6F76656D656E7458207C7C20652E6D6F76656D656E745920292029207B20746869732E73657441637469766528202B6F70742E646174617365742E696E6465782C2066616C736520293B207D0A20202020';
wwv_flow_imp.g_varchar2_table(131) := '20202020202020207D20293B0A202020202020202020202020746869732E6C6973742E6164644576656E744C697374656E6572282022636C69636B222C2065203D3E207B0A20202020202020202020202020202020636F6E7374206F7074203D20652E74';
wwv_flow_imp.g_varchar2_table(132) := '61726765742E636C6F736573742820222E74782D50616C657474652D6974656D2220293B0A2020202020202020202020202020202069662028206F70742029207B20746869732E72756E2820746869732E6974656D735B202B6F70742E64617461736574';
wwv_flow_imp.g_varchar2_table(133) := '2E696E646578205D2C20652E6374726C4B6579207C7C20652E6D6574614B657920293B207D0A2020202020202020202020207D20293B0A202020202020202020202020746869732E6C6973742E6164644576656E744C697374656E65722820226D6F7573';
wwv_flow_imp.g_varchar2_table(134) := '65646F776E222C2065203D3E20652E70726576656E7444656661756C74282920293B202F2F206B6565702074686520666F63757320696E207468652073656172636820626F780A0A202020202020202020202020746869732E737461747573203D20656C';
wwv_flow_imp.g_varchar2_table(135) := '282022646976222C202274782D50616C657474652D7374617475732220293B0A202020202020202020202020746869732E7374617475732E736574417474726962757465282022726F6C65222C20227374617475732220293B0A0A202020202020202020';
wwv_flow_imp.g_varchar2_table(136) := '202020636F6E737420666F6F74203D20656C282022646976222C202274782D50616C657474652D666F6F742220293B0A2020202020202020202020205B205B2022E28691E28693222C2022746F206D6F766522205D2C205B2022E286B5222C2022746F20';
wwv_flow_imp.g_varchar2_table(137) := '6F70656E22205D2C205B2022457363222C2022746F20636C6F736522205D205D2E666F7245616368282068203D3E207B0A20202020202020202020202020202020636F6E7374207370616E203D20656C2820227370616E2220293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(138) := '20202020202020207370616E2E617070656E642820656C2820226B6264222C206E756C6C2C20685B2030205D20292C20222022202B20685B2031205D20293B0A20202020202020202020202020202020666F6F742E617070656E6428207370616E20293B';
wwv_flow_imp.g_varchar2_table(139) := '0A2020202020202020202020207D20293B0A202020202020202020202020666F6F742E736574417474726962757465282022617269612D68696464656E222C2022747275652220293B0A0A202020202020202020202020746869732E6469616C6F672E61';
wwv_flow_imp.g_varchar2_table(140) := '7070656E6428206261722C20746869732E6C6973742C20746869732E7374617475732C20666F6F7420293B0A202020202020202020202020746869732E6469616C6F672E6164644576656E744C697374656E65722820226B6579646F776E222C2065203D';
wwv_flow_imp.g_varchar2_table(141) := '3E207B0A202020202020202020202020202020206966202820652E6B6579203D3D3D2022546162222029207B20652E70726576656E7444656661756C7428293B20746869732E696E7075742E666F63757328293B207D0A2020202020202020202020207D';
wwv_flow_imp.g_varchar2_table(142) := '20293B0A202020202020202020202020746869732E726F6F742E617070656E6428206261636B64726F702C20746869732E6469616C6F6720293B0A202020202020202020202020646F63756D656E742E626F64792E617070656E642820746869732E726F';
wwv_flow_imp.g_varchar2_table(143) := '6F7420293B0A20202020202020207D0A0A2020202020202020746F67676C652829207B206966202820746869732E69734F70656E2029207B20746869732E636C6F736528293B207D20656C7365207B20746869732E6F70656E28293B207D207D0A0A2020';
wwv_flow_imp.g_varchar2_table(144) := '2020202020206F70656E282071756572792029207B0A20202020202020202020202069662028206F70656E50616C65747465202626206F70656E50616C6574746520213D3D20746869732029207B206F70656E50616C657474652E636C6F736528206661';
wwv_flow_imp.g_varchar2_table(145) := '6C736520293B207D0A202020202020202020202020696620282021746869732E726F6F742029207B20746869732E6275696C6428293B207D0A202020202020202020202020696620282021746869732E69734F70656E2029207B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(146) := '20202020202020746869732E6C617374466F637573203D20646F63756D656E742E616374697665456C656D656E743B0A20202020202020202020202020202020746869732E69734F70656E203D20747275653B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(147) := '6F70656E50616C65747465203D20746869733B0A20202020202020202020202020202020746869732E726F6F742E68696464656E203D2066616C73653B0A20202020202020202020202020202020646F63756D656E742E646F63756D656E74456C656D65';
wwv_flow_imp.g_varchar2_table(148) := '6E742E636C6173734C6973742E61646428202274782D50616C657474652D6C6F636B2220293B0A2020202020202020202020202020202072657175657374416E696D6174696F6E4672616D6528202829203D3E20746869732E726F6F742E636C6173734C';
wwv_flow_imp.g_varchar2_table(149) := '6973742E61646428202269732D6F70656E22202920293B0A20202020202020202020202020202020617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D636F6D6D616E6470616C657474652D';
wwv_flow_imp.g_varchar2_table(150) := '6F70656E2220293B0A2020202020202020202020207D0A202020202020202020202020746869732E696E7075742E76616C7565203D207175657279207C7C2022223B0A202020202020202020202020746869732E696E7075742E666F63757328293B0A20';
wwv_flow_imp.g_varchar2_table(151) := '2020202020202020202020746869732E6C6F616428292E616C7761797328202829203D3E20746869732E72656E646572282920293B0A202020202020202020202020746869732E72656E64657228293B0A20202020202020207D0A0A2020202020202020';
wwv_flow_imp.g_varchar2_table(152) := '636C6F73652820726573746F7265466F6375732029207B0A202020202020202020202020696620282021746869732E69734F70656E2029207B2072657475726E3B207D0A202020202020202020202020746869732E69734F70656E203D2066616C73653B';
wwv_flow_imp.g_varchar2_table(153) := '0A20202020202020202020202069662028206F70656E50616C65747465203D3D3D20746869732029207B206F70656E50616C65747465203D206E756C6C3B207D0A202020202020202020202020746869732E726F6F742E636C6173734C6973742E72656D';
wwv_flow_imp.g_varchar2_table(154) := '6F766528202269732D6F70656E2220293B0A202020202020202020202020746869732E726F6F742E68696464656E203D20747275653B0A202020202020202020202020646F63756D656E742E646F63756D656E74456C656D656E742E636C6173734C6973';
wwv_flow_imp.g_varchar2_table(155) := '742E72656D6F766528202274782D50616C657474652D6C6F636B2220293B0A2020202020202020202020206966202820726573746F7265466F63757320213D3D2066616C736520262620746869732E6C617374466F63757320262620746869732E6C6173';
wwv_flow_imp.g_varchar2_table(156) := '74466F6375732E666F6375732029207B20746869732E6C617374466F6375732E666F63757328293B207D0A202020202020202020202020617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D';
wwv_flow_imp.g_varchar2_table(157) := '636F6D6D616E6470616C657474652D636C6F73652220293B0A20202020202020207D0A0A20202020202020202F2F2074686520726567696F6E20736F75726365277320636F6D6D616E64732C206F6E63653B207265667265736828292061736B73206167';
wwv_flow_imp.g_varchar2_table(158) := '61696E0A20202020202020206C6F61642829207B0A2020202020202020202020206966202820746869732E7365727665722029207B2072657475726E20746869732E7365727665723B207D0A202020202020202020202020746869732E6C6F6164696E67';
wwv_flow_imp.g_varchar2_table(159) := '203D20747275653B0A202020202020202020202020746869732E736572766572203D20617065782E7365727665722E706C7567696E2820746869732E6F2E616A61784964656E7469666965722C207B207830313A20224C495354222C2070616765497465';
wwv_flow_imp.g_varchar2_table(160) := '6D733A20746869732E6F2E6974656D73546F5375626D6974207D2C207B2064617461547970653A20226A736F6E22207D20290A202020202020202020202020202020202E646F6E65282064617461203D3E207B20746869732E736572766572436F6D6D61';
wwv_flow_imp.g_varchar2_table(161) := '6E6473203D202820646174612E636F6D6D616E6473207C7C205B5D20292E6D6170282063203D3E20636F6D6D616E642820632C2022717565727922202920293B20746869732E6661696C6564203D2066616C73653B207D20290A20202020202020202020';
wwv_flow_imp.g_varchar2_table(162) := '2020202020202E6661696C28202829203D3E207B20746869732E736572766572436F6D6D616E6473203D205B5D3B20746869732E6661696C6564203D20747275653B20746869732E736572766572203D206E756C6C3B207D20290A202020202020202020';
wwv_flow_imp.g_varchar2_table(163) := '202020202020202E616C7761797328202829203D3E207B20746869732E6C6F6164696E67203D2066616C73653B207D20293B0A20202020202020202020202072657475726E20746869732E7365727665723B0A20202020202020207D0A0A202020202020';
wwv_flow_imp.g_varchar2_table(164) := '2020726566726573682829207B0A202020202020202020202020746869732E736572766572203D206E756C6C3B0A202020202020202020202020636F6E73742070203D20746869732E6C6F616428293B0A20202020202020202020202069662028207468';
wwv_flow_imp.g_varchar2_table(165) := '69732E69734F70656E2029207B20702E616C7761797328202829203D3E20746869732E72656E646572282920293B207D0A20202020202020202020202072657475726E20703B0A20202020202020207D0A0A2020202020202020616464436F6D6D616E64';
wwv_flow_imp.g_varchar2_table(166) := '7328206C6973742029207B0A202020202020202020202020282041727261792E6973417272617928206C6973742029203F206C697374203A205B206C697374205D20292E666F7245616368282063203D3E20746869732E6A73436F6D6D616E64732E7075';
wwv_flow_imp.g_varchar2_table(167) := '73682820636F6D6D616E642820632C20226A73222029202920293B0A2020202020202020202020206966202820746869732E69734F70656E2029207B20746869732E72656E64657228293B207D0A20202020202020207D0A0A2020202020202020616C6C';
wwv_flow_imp.g_varchar2_table(168) := '436F6D6D616E64732829207B0A20202020202020202020202072657475726E205B5D2E636F6E636174280A20202020202020202020202020202020746869732E736F75726365732E696E636C756465732820226E6176222029203F206E6176436F6D6D61';
wwv_flow_imp.g_varchar2_table(169) := '6E64732829203A205B5D2C0A20202020202020202020202020202020746869732E736572766572436F6D6D616E6473207C7C205B5D2C0A20202020202020202020202020202020746869732E6A73436F6D6D616E64732C0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(170) := '20202020746869732E736F75726365732E696E636C75646573282022616374696F6E73222029203F20616374696F6E436F6D6D616E64732829203A205B5D0A202020202020202020202020293B0A20202020202020207D0A0A2020202020202020726563';
wwv_flow_imp.g_varchar2_table(171) := '656E744B6579732829207B0A202020202020202020202020747279207B2072657475726E204A534F4E2E706172736528206C6F63616C53746F726167652E6765744974656D2820746869732E73746F72654B65792029207C7C20225B5D2220293B207D20';
wwv_flow_imp.g_varchar2_table(172) := '6361746368202820652029207B2072657475726E205B5D3B207D0A20202020202020207D0A0A202020202020202072656D656D6265722820636D642029207B0A2020202020202020202020206966202820212820746869732E6F2E726563656E74203E20';
wwv_flow_imp.g_varchar2_table(173) := '3020292029207B2072657475726E3B207D0A202020202020202020202020636F6E7374206B657973203D205B20636D642E6B6579205D2E636F6E6361742820746869732E726563656E744B65797328292E66696C74657228206B203D3E206B20213D3D20';
wwv_flow_imp.g_varchar2_table(174) := '636D642E6B6579202920292E736C6963652820302C20746869732E6F2E726563656E7420293B0A202020202020202020202020747279207B206C6F63616C53746F726167652E7365744974656D2820746869732E73746F72654B65792C204A534F4E2E73';
wwv_flow_imp.g_varchar2_table(175) := '7472696E6769667928206B657973202920293B207D206361746368202820652029207B202F2A2070726976617465206D6F6465202A2F207D0A20202020202020207D0A0A202020202020202072656E6465722829207B0A20202020202020202020202069';
wwv_flow_imp.g_varchar2_table(176) := '6620282021746869732E726F6F742029207B2072657475726E3B207D0A202020202020202020202020636F6E737420616C6C203D20746869732E616C6C436F6D6D616E647328292C0A2020202020202020202020202020202071203D206E6F726D282074';
wwv_flow_imp.g_varchar2_table(177) := '6869732E696E7075742E76616C756520292E7472696D28292C0A202020202020202020202020202020206D6178203D20746869732E6F2E6D6178526573756C7473207C7C2036303B0A2020202020202020202020206C65742073656374696F6E733B0A20';
wwv_flow_imp.g_varchar2_table(178) := '20202020202020202020206966202820712029207B0A20202020202020202020202020202020636F6E737420746F6B656E73203D20712E73706C697428202F5C732B2F20293B0A20202020202020202020202020202020636F6E73742068697473203D20';
wwv_flow_imp.g_varchar2_table(179) := '616C6C2E6D617028202820636D642C206E2029203D3E2028207B20636D642C206E2C20723A2072616E6B2820636D642C20746F6B656E732029207D202920292E66696C746572282068203D3E20682E7220290A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(180) := '2020202E736F727428202820612C20622029203D3E20622E722E73636F7265202D20612E722E73636F7265207C7C20612E6E202D20622E6E20292E736C6963652820302C206D617820293B0A2020202020202020202020202020202073656374696F6E73';
wwv_flow_imp.g_varchar2_table(181) := '203D205B207B206C6162656C3A2022222C206974656D733A20686974732E6D6170282068203D3E2028207B20636D643A20682E636D642C206D61726B733A20682E722E6D61726B73207D202920292C2073686F7747726F75703A2074727565207D205D3B';
wwv_flow_imp.g_varchar2_table(182) := '0A2020202020202020202020207D20656C7365207B0A2020202020202020202020202020202073656374696F6E73203D205B5D3B0A20202020202020202020202020202020636F6E73742062794B6579203D206E6577204D61702820616C6C2E6D617028';
wwv_flow_imp.g_varchar2_table(183) := '2063203D3E205B20632E6B65792C2063205D202920293B0A20202020202020202020202020202020636F6E737420726563656E74203D20746869732E726563656E744B65797328292E6D617028206B203D3E2062794B65792E67657428206B202920292E';
wwv_flow_imp.g_varchar2_table(184) := '66696C7465722820426F6F6C65616E20292E736C6963652820302C20746869732E6F2E726563656E74207C7C203020293B0A202020202020202020202020202020206966202820726563656E742E6C656E6774682029207B2073656374696F6E732E7075';
wwv_flow_imp.g_varchar2_table(185) := '736828207B206C6162656C3A2022526563656E74222C206974656D733A20726563656E742E6D61702820636D64203D3E2028207B20636D64207D202920292C2073686F7747726F75703A2074727565207D20293B207D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(186) := '202020636F6E73742067726F757073203D206E6577204D617028293B0A20202020202020202020202020202020616C6C2E666F7245616368282063203D3E207B0A2020202020202020202020202020202020202020636F6E73742067203D20632E67207C';
wwv_flow_imp.g_varchar2_table(187) := '7C2022436F6D6D616E6473223B0A202020202020202020202020202020202020202069662028202167726F7570732E68617328206720292029207B2067726F7570732E7365742820672C205B5D20293B207D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(188) := '20202067726F7570732E67657428206720292E7075736828207B20636D643A2063207D20293B0A202020202020202020202020202020207D20293B0A202020202020202020202020202020206C657420726F6F6D203D206D61783B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(189) := '202020202020202067726F7570732E666F7245616368282028206974656D732C206C6162656C2029203D3E207B0A20202020202020202020202020202020202020206966202820726F6F6D203C3D20302029207B2072657475726E3B207D0A2020202020';
wwv_flow_imp.g_varchar2_table(190) := '20202020202020202020202020202073656374696F6E732E7075736828207B206C6162656C2C206974656D733A206974656D732E736C6963652820302C20726F6F6D2029207D20293B0A2020202020202020202020202020202020202020726F6F6D202D';
wwv_flow_imp.g_varchar2_table(191) := '3D206974656D732E6C656E6774683B0A202020202020202020202020202020207D20293B0A2020202020202020202020207D0A0A202020202020202020202020746869732E6C6973742E74657874436F6E74656E74203D2022223B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(192) := '20202020746869732E6974656D73203D205B5D3B0A20202020202020202020202073656374696F6E732E666F7245616368282028207365632C20732029203D3E207B0A202020202020202020202020202020206966202820217365632E6974656D732E6C';
wwv_flow_imp.g_varchar2_table(193) := '656E6774682029207B2072657475726E3B207D0A20202020202020202020202020202020636F6E73742067726F7570203D20656C282022646976222C202274782D50616C657474652D67726F75702220293B0A2020202020202020202020202020202067';
wwv_flow_imp.g_varchar2_table(194) := '726F75702E736574417474726962757465282022726F6C65222C202267726F75702220293B0A2020202020202020202020202020202069662028207365632E6C6162656C2029207B0A2020202020202020202020202020202020202020636F6E73742068';
wwv_flow_imp.g_varchar2_table(195) := '656164203D20656C282022646976222C202274782D50616C657474652D67726F75704C6162656C222C207365632E6C6162656C20293B0A2020202020202020202020202020202020202020686561642E6964203D20746869732E726567696F6E4964202B';
wwv_flow_imp.g_varchar2_table(196) := '20225F6722202B20733B0A202020202020202020202020202020202020202067726F75702E736574417474726962757465282022617269612D6C6162656C6C65646279222C20686561642E696420293B0A20202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(197) := '2067726F75702E617070656E6428206865616420293B0A202020202020202020202020202020207D20656C7365207B0A202020202020202020202020202020202020202067726F75702E736574417474726962757465282022617269612D6C6162656C22';
wwv_flow_imp.g_varchar2_table(198) := '2C2022526573756C74732220293B0A202020202020202020202020202020207D0A202020202020202020202020202020207365632E6974656D732E666F724561636828206974203D3E207B0A202020202020202020202020202020202020202067726F75';
wwv_flow_imp.g_varchar2_table(199) := '702E617070656E642820746869732E6F7074696F6E282069742E636D642C2069742E6D61726B732C207365632E73686F7747726F75702C20746869732E6974656D732E6C656E677468202920293B0A202020202020202020202020202020202020202074';
wwv_flow_imp.g_varchar2_table(200) := '6869732E6974656D732E70757368282069742E636D6420293B0A202020202020202020202020202020207D20293B0A20202020202020202020202020202020746869732E6C6973742E617070656E64282067726F757020293B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(201) := '20207D20293B0A0A2020202020202020202020206C6574206D657373616765203D2022223B0A202020202020202020202020696620282021746869732E6974656D732E6C656E6774682029207B0A202020202020202020202020202020206D6573736167';
wwv_flow_imp.g_varchar2_table(202) := '65203D20746869732E6C6F6164696E67203F20224C6F6164696E6720636F6D6D616E64732E2E2E22203A20746869732E6661696C6564203F202254686520636F6D6D616E647320636F756C64206E6F74206265206C6F616465642E220A20202020202020';
wwv_flow_imp.g_varchar2_table(203) := '202020202020202020202020203A2071203F20224E6F20636F6D6D616E6473206D6174636820E2809C22202B20746869732E696E7075742E76616C75652E7472696D2829202B2022E2809D2E22203A20224E6F20636F6D6D616E64732E223B0A20202020';
wwv_flow_imp.g_varchar2_table(204) := '202020202020202020202020746869732E6C6973742E617070656E642820656C282022646976222C202274782D50616C657474652D656D707479222C206D657373616765202920293B0A2020202020202020202020207D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(205) := '746869732E7374617475732E74657874436F6E74656E74203D20746869732E6974656D732E6C656E677468203F20746869732E6974656D732E6C656E677468202B202820746869732E6974656D732E6C656E677468203D3D3D2031203F202220636F6D6D';
wwv_flow_imp.g_varchar2_table(206) := '616E6422203A202220636F6D6D616E6473222029203A206D6573736167653B0A202020202020202020202020746869732E7365744163746976652820746869732E6974656D732E6C656E677468203F2030203A202D3120293B0A20202020202020207D0A';
wwv_flow_imp.g_varchar2_table(207) := '0A20202020202020206F7074696F6E2820636D642C206D61726B732C2073686F7747726F75702C20696E6465782029207B0A202020202020202020202020636F6E7374206F7074203D20656C282022646976222C202274782D50616C657474652D697465';
wwv_flow_imp.g_varchar2_table(208) := '6D2220292C0A2020202020202020202020202020202069636F6E203D20656C2820227370616E222C202274782D50616C657474652D69636F6E2220292C0A202020202020202020202020202020206D61696E203D20656C2820227370616E222C20227478';
wwv_flow_imp.g_varchar2_table(209) := '2D50616C657474652D6D61696E2220292C0A202020202020202020202020202020207469746C65203D20656C2820227370616E222C202274782D50616C657474652D7469746C652220293B0A2020202020202020202020206F70742E6964203D20746869';
wwv_flow_imp.g_varchar2_table(210) := '732E726567696F6E4964202B20225F6F707422202B20696E6465783B0A2020202020202020202020206F70742E646174617365742E696E646578203D20696E6465783B0A2020202020202020202020206F70742E73657441747472696275746528202272';
wwv_flow_imp.g_varchar2_table(211) := '6F6C65222C20226F7074696F6E2220293B0A2020202020202020202020206F70742E736574417474726962757465282022617269612D73656C6563746564222C202266616C73652220293B0A20202020202020202020202069636F6E2E73657441747472';
wwv_flow_imp.g_varchar2_table(212) := '6962757465282022617269612D68696464656E222C2022747275652220293B0A20202020202020202020202069636F6E2E617070656E642820656C2820227370616E222C202266612022202B202820636D642E69207C7C202820636D642E6C203F202266';
wwv_flow_imp.g_varchar2_table(213) := '612D6172726F772D726967687422203A202266612D626F6C742220292029202920293B0A0A2020202020202020202020202F2F20746865206C6162656C2077697468206D617463686564206C65747465727320696E203C6D61726B3E3B20746865207061';
wwv_flow_imp.g_varchar2_table(214) := '74682070617274206973206D757465640A202020202020202020202020636F6E73742074657874203D206C6162656C2820636D6420292C2073706C6974203D20636D642E70617468203F20636D642E706174682E6C656E677468202B2033203A20303B0A';
wwv_flow_imp.g_varchar2_table(215) := '202020202020202020202020636F6E7374207772697465203D20282066726F6D2C20746F2C20706172656E742029203D3E207B0A202020202020202020202020202020206C65742072756E203D2022222C20696E4D61726B203D2066616C73653B0A2020';
wwv_flow_imp.g_varchar2_table(216) := '2020202020202020202020202020636F6E737420666C757368203D202829203D3E207B0A2020202020202020202020202020202020202020696620282072756E2029207B20706172656E742E617070656E642820696E4D61726B203F20656C2820226D61';
wwv_flow_imp.g_varchar2_table(217) := '726B222C206E756C6C2C2072756E2029203A20646F63756D656E742E637265617465546578744E6F6465282072756E202920293B207D0A202020202020202020202020202020202020202072756E203D2022223B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(218) := '207D3B0A20202020202020202020202020202020666F722028206C65742069203D2066726F6D3B2069203C20746F3B20692B2B2029207B0A2020202020202020202020202020202020202020636F6E7374206D203D20212128206D61726B73202626206D';
wwv_flow_imp.g_varchar2_table(219) := '61726B732E686173282069202920293B0A202020202020202020202020202020202020202069662028206D20213D3D20696E4D61726B2029207B20666C75736828293B20696E4D61726B203D206D3B207D0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(220) := '202072756E202B3D20746578745B2069205D3B0A202020202020202020202020202020207D0A20202020202020202020202020202020666C75736828293B0A2020202020202020202020207D3B0A202020202020202020202020696620282073706C6974';
wwv_flow_imp.g_varchar2_table(221) := '2029207B0A20202020202020202020202020202020636F6E73742070203D20656C2820227370616E222C202274782D50616C657474652D706174682220293B0A2020202020202020202020202020202077726974652820302C2073706C69742C20702029';
wwv_flow_imp.g_varchar2_table(222) := '3B0A202020202020202020202020202020207469746C652E617070656E6428207020293B0A2020202020202020202020207D0A2020202020202020202020207772697465282073706C69742C20746578742E6C656E6774682C207469746C6520293B0A20';
wwv_flow_imp.g_varchar2_table(223) := '20202020202020202020206D61696E2E617070656E6428207469746C6520293B0A2020202020202020202020206966202820636D642E642029207B206D61696E2E617070656E642820656C2820227370616E222C202274782D50616C657474652D646573';
wwv_flow_imp.g_varchar2_table(224) := '63222C20636D642E64202920293B207D0A0A202020202020202020202020636F6E7374206D657461203D20656C2820227370616E222C202274782D50616C657474652D6D6574612220293B0A202020202020202020202020696620282073686F7747726F';
wwv_flow_imp.g_varchar2_table(225) := '757020262620636D642E672029207B206D6574612E617070656E642820656C2820227370616E222C202274782D50616C657474652D746167222C20636D642E67202920293B207D0A2020202020202020202020206966202820636D642E732029207B206D';
wwv_flow_imp.g_varchar2_table(226) := '6574612E617070656E642820656C2820226B6264222C202274782D50616C657474652D6B6264222C20636D642E73202920293B207D0A2020202020202020202020206F70742E617070656E64282069636F6E2C206D61696E2C206D65746120293B0A2020';
wwv_flow_imp.g_varchar2_table(227) := '2020202020202020202072657475726E206F70743B0A20202020202020207D0A0A20202020202020207365744163746976652820696E6465782C207363726F6C6C2029207B0A202020202020202020202020636F6E73742070726576203D20746869732E';
wwv_flow_imp.g_varchar2_table(228) := '6C6973742E717565727953656C6563746F722820222E74782D50616C657474652D6974656D2E69732D6163746976652220293B0A2020202020202020202020206966202820707265762029207B20707265762E636C6173734C6973742E72656D6F766528';
wwv_flow_imp.g_varchar2_table(229) := '202269732D6163746976652220293B20707265762E736574417474726962757465282022617269612D73656C6563746564222C202266616C73652220293B207D0A202020202020202020202020746869732E616374697665203D20696E6465783B0A2020';
wwv_flow_imp.g_varchar2_table(230) := '20202020202020202020636F6E7374206F7074203D20696E646578203E3D2030203F20646F63756D656E742E676574456C656D656E74427949642820746869732E726567696F6E4964202B20225F6F707422202B20696E6465782029203A206E756C6C3B';
wwv_flow_imp.g_varchar2_table(231) := '0A20202020202020202020202069662028206F70742029207B0A202020202020202020202020202020206F70742E636C6173734C6973742E61646428202269732D6163746976652220293B0A202020202020202020202020202020206F70742E73657441';
wwv_flow_imp.g_varchar2_table(232) := '7474726962757465282022617269612D73656C6563746564222C2022747275652220293B0A20202020202020202020202020202020746869732E696E7075742E736574417474726962757465282022617269612D61637469766564657363656E64616E74';
wwv_flow_imp.g_varchar2_table(233) := '222C206F70742E696420293B0A2020202020202020202020202020202069662028207363726F6C6C20213D3D2066616C73652029207B206F70742E7363726F6C6C496E746F5669657728207B20626C6F636B3A20226E65617265737422207D20293B207D';
wwv_flow_imp.g_varchar2_table(234) := '0A2020202020202020202020207D20656C7365207B0A20202020202020202020202020202020746869732E696E7075742E72656D6F7665417474726962757465282022617269612D61637469766564657363656E64616E742220293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(235) := '20202020207D0A20202020202020207D0A0A20202020202020206F6E4B65792820652029207B0A202020202020202020202020636F6E7374206E203D20746869732E6974656D732E6C656E6774683B0A2020202020202020202020206966202820652E69';
wwv_flow_imp.g_varchar2_table(236) := '73436F6D706F73696E672029207B2072657475726E3B207D0A202020202020202020202020737769746368202820652E6B65792029207B0A202020202020202020202020202020206361736520224172726F77446F776E223A0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(237) := '20202020202020202020652E70726576656E7444656661756C7428293B0A202020202020202020202020202020202020202069662028206E2029207B20746869732E73657441637469766528202820746869732E616374697665202B203120292025206E';
wwv_flow_imp.g_varchar2_table(238) := '20293B207D0A2020202020202020202020202020202020202020627265616B3B0A202020202020202020202020202020206361736520224172726F775570223A0A2020202020202020202020202020202020202020652E70726576656E7444656661756C';
wwv_flow_imp.g_varchar2_table(239) := '7428293B0A202020202020202020202020202020202020202069662028206E2029207B20746869732E73657441637469766528202820746869732E616374697665202D2031202B206E20292025206E20293B207D0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(240) := '2020202020627265616B3B0A2020202020202020202020202020202063617365202250616765446F776E223A0A2020202020202020202020202020202020202020652E70726576656E7444656661756C7428293B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(241) := '202020202069662028206E2029207B20746869732E73657441637469766528204D6174682E6D696E28206E202D20312C20746869732E616374697665202B2038202920293B207D0A2020202020202020202020202020202020202020627265616B3B0A20';
wwv_flow_imp.g_varchar2_table(242) := '202020202020202020202020202020636173652022506167655570223A0A2020202020202020202020202020202020202020652E70726576656E7444656661756C7428293B0A202020202020202020202020202020202020202069662028206E2029207B';
wwv_flow_imp.g_varchar2_table(243) := '20746869732E73657441637469766528204D6174682E6D61782820302C20746869732E616374697665202D2038202920293B207D0A2020202020202020202020202020202020202020627265616B3B0A2020202020202020202020202020202063617365';
wwv_flow_imp.g_varchar2_table(244) := '2022456E746572223A0A2020202020202020202020202020202020202020652E70726576656E7444656661756C7428293B0A20202020202020202020202020202020202020206966202820746869732E616374697665203E3D20302029207B2074686973';
wwv_flow_imp.g_varchar2_table(245) := '2E72756E2820746869732E6974656D735B20746869732E616374697665205D2C20652E6374726C4B6579207C7C20652E6D6574614B657920293B207D0A2020202020202020202020202020202020202020627265616B3B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(246) := '20202020636173652022457363617065223A0A2020202020202020202020202020202020202020652E70726576656E7444656661756C7428293B0A2020202020202020202020202020202020202020652E73746F7050726F7061676174696F6E28293B0A';
wwv_flow_imp.g_varchar2_table(247) := '2020202020202020202020202020202020202020746869732E636C6F736528293B0A2020202020202020202020202020202020202020627265616B3B0A2020202020202020202020207D0A20202020202020207D0A0A20202020202020202F2F206E6577';
wwv_flow_imp.g_varchar2_table(248) := '5461623A204374726C2F436D64202B20456E746572206F7220636C69636B206F70656E732061206C696E6B20696E2061206E6577207461620A202020202020202072756E2820636D642C206E65775461622029207B0A2020202020202020202020206966';
wwv_flow_imp.g_varchar2_table(249) := '20282021636D642029207B2072657475726E3B207D0A202020202020202020202020746869732E72656D656D6265722820636D6420293B0A202020202020202020202020636F6E7374206C696E6B203D20636D642E6C2C2065787465726E616C203D206E';
wwv_flow_imp.g_varchar2_table(250) := '6577546162202626206C696E6B20262620212F5E6A6176617363726970743A2F692E7465737428206C696E6B20293B0A202020202020202020202020746869732E636C6F73652820216C696E6B207C7C2065787465726E616C20293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(251) := '20202020206966202820746869732E6F2E7365744974656D2029207B20617065782E6974656D2820746869732E6F2E7365744974656D20292E73657456616C75652820636D642E7620213D206E756C6C203F20636D642E76203A20636D642E7420293B20';
wwv_flow_imp.g_varchar2_table(252) := '7D0A202020202020202020202020617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D636F6D6D616E6470616C657474652D73656C656374222C0A202020202020202020202020202020207B';
wwv_flow_imp.g_varchar2_table(253) := '207469746C653A20636D642E742C2076616C75653A20636D642E7620213D206E756C6C203F20636D642E76203A206E756C6C2C2067726F75703A20636D642E672C206C696E6B3A206C696E6B207C7C206E756C6C2C20616374696F6E3A20636D642E6120';
wwv_flow_imp.g_varchar2_table(254) := '7C7C206E756C6C207D20293B0A2020202020202020202020206966202820636D642E666E2029207B0A20202020202020202020202020202020636D642E666E2820636D6420293B0A2020202020202020202020207D20656C7365206966202820636D642E';
wwv_flow_imp.g_varchar2_table(255) := '6120262620617065782E616374696F6E732E6C6F6F6B75702820636D642E6120292029207B0A20202020202020202020202020202020617065782E616374696F6E732E696E766F6B652820636D642E6120293B0A2020202020202020202020207D20656C';
wwv_flow_imp.g_varchar2_table(256) := '736520696620282065787465726E616C2029207B0A2020202020202020202020202020202077696E646F772E6F70656E28206E65772055524C28206C696E6B2C20646F63756D656E742E6261736555524920292E687265662C20225F626C616E6B222C20';
wwv_flow_imp.g_varchar2_table(257) := '226E6F6F70656E65722220293B0A2020202020202020202020207D20656C73652069662028206C696E6B2029207B0A20202020202020202020202020202020617065782E6E617669676174696F6E2E726564697265637428206C696E6B20293B0A202020';
wwv_flow_imp.g_varchar2_table(258) := '2020202020202020207D0A20202020202020207D0A202020207D0A0A20202020636F6E73742070616C6574746573203D207B7D3B0A202020206E732E636F6D6D616E6450616C65747465203D207B0A2020202020202020696E69742820726567696F6E49';
wwv_flow_imp.g_varchar2_table(259) := '642C206F7074696F6E732029207B0A202020202020202020202020636F6E73742070203D206E65772050616C657474652820726567696F6E49642C206F7074696F6E7320293B0A20202020202020202020202070616C65747465735B20726567696F6E49';
wwv_flow_imp.g_varchar2_table(260) := '64205D203D20703B0A202020202020202020202020617065782E726567696F6E2E6372656174652820726567696F6E49642C207B0A20202020202020202020202020202020747970653A20225465636852657658436F6D6D616E6450616C65747465222C';
wwv_flow_imp.g_varchar2_table(261) := '0A202020202020202020202020202020206F70656E3A207175657279203D3E20702E6F70656E2820717565727920292C0A20202020202020202020202020202020636C6F73653A202829203D3E20702E636C6F736528292C0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(262) := '2020202020746F67676C653A202829203D3E20702E746F67676C6528292C0A20202020202020202020202020202020726566726573683A202829203D3E20702E7265667265736828292C0A20202020202020202020202020202020616464436F6D6D616E';
wwv_flow_imp.g_varchar2_table(263) := '64733A206C697374203D3E20702E616464436F6D6D616E647328206C69737420292C0A2020202020202020202020202020202069734F70656E3A202829203D3E20702E69734F70656E2C0A202020202020202020202020202020207769646765743A2028';
wwv_flow_imp.g_varchar2_table(264) := '29203D3E20242820702E726F6F74207C7C205B5D20290A2020202020202020202020207D20293B0A20202020202020207D2C0A20202020202020206765743A20726567696F6E4964203D3E2070616C65747465735B20726567696F6E4964205D0A202020';
wwv_flow_imp.g_varchar2_table(265) := '207D3B0A7D20292820617065782E6A51756572792C206170657820293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6208110683861070)
,p_plugin_id=>wwv_flow_imp.id(6205483822861062)
,p_file_name=>'command-palette.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
