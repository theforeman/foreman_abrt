Deface::Override.new(:virtual_path  => 'hosts/show',
                     :name          => 'add_bug_report_tab',
                     :insert_bottom => 'ul.nav-tabs',
                     :partial       => 'abrt_reports/host_tab'
)

Deface::Override.new(:virtual_path  => 'hosts/show',
                     :name          => 'add_bug_report_tab_pane',
                     :insert_bottom => 'div.tab-content',
                     :partial       => 'abrt_reports/host_tab_pane'
)
