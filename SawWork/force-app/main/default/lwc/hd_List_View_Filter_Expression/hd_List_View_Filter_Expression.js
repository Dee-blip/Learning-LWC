import { LightningElement, api } from 'lwc';

export default class Hd_List_View_Filter_Expression extends LightningElement {
    @api isOpen = false;
    listViewMetadata;
    operatorLabelMap = new Map([
        ['Contains', 'contains'],
        ['Equals', 'equals'],
        ['Excludes', 'excludes'],
        ['GreaterOrEqual', 'greater or equal'],
        ['GreaterThan', 'greater than'],
        ['Includes', 'includes'],
        ['LessOrEqual', 'less or equal'],
        ['LessThan', 'less than'],
        ['NotContain', 'does not contain'],
        ['NotEqual', 'not equal to'],
        ['StartsWith', 'starts with']
    ]);


    get panelState() {
        return (this.isOpen) ? 'slds-panel slds-size_medium slds-panel_docked slds-panel_docked-right slds-panel_drawer slds-is-open' :
            'slds-panel slds-size_medium slds-panel_docked slds-panel_docked-right slds-panel_drawer';
    }

    @api setFilters(filters) {
        let order = 1;
        filters.filteredByInfo.forEach(filter => {
            filter.order = order++;
            filter.operatorLabel = this.operatorLabelMap.get(filter.operator);
        });
        this.listViewMetadata = filters;
    }
}