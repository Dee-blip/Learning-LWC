import { LightningElement, track, api } from 'lwc';

export default class ScMultiselectCombo extends LightningElement {

    @api variant = 'label-hidden'; // 'label-hidden', 'label-inline', 'label-stacked'
    @api placeholder = '';
    @api options = [];

    @api label = '';
    @api itemsLabel = 'Items';
    @api disabled;
    @api required;
    @api iconName;// = 'standard:account';
    @api filteritemsLabel = 'Filter Selected Items';
    @api selectallLabel = 'Select All';
    @api unselectallLabel = 'Clear All';
    @api cancelLabel = 'Cancel';
    @api doneLabel = 'Done';
    
    @api requiredErrorMessage = 'Select at least one item';
    @api noResultsMsg = 'No Results';

    _selectedItems;

    @api get selectedItems() {
        return this._selectedItems;
    }
    set selectedItems(val) {
        // this._selectedItems = val;
        this.isReadMode = true;
        this.processList(val);
        // this.processList();
        // this.selectAll = this._selectedItems && this.options && this._selectedItems.length  === this.options.length;
    }
    

    @track isReadMode = true;
    @track selectAll = false;
    @track inpErrorMsg;
    @track inpCss = 'slds-combobox_container slds-has-selection';
    @track searchStr;
    selectedItemsOld;

    get comboBoxCss() {
        return this.isReadMode ? 'slds-dropdown slds-dropdown_length-with-icon-10 slds-dropdown_fluid inactive'
            : 'slds-dropdown slds-dropdown_length-with-icon-10 slds-dropdown_fluid active';
    }

    get selItemCss() {
        return 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right';//: 'slds-input-has-icon_right' );
    }

    get showLabel() {
        return this.variant !== 'label-hidden';
    }

    get formElCss() {

        if (this.variant === 'label-inline') {
            return 'slds-form-element slds-form-element_horizontal';
        }
        else if (this.variant === 'label-stacked') {
            return 'slds-form-element slds-form-element_stacked';
        }
        return 'slds-form-element';
    }
    @track processedListData = [];
    processList(selItems) {
        this._selectedItems = selItems;
        this.selectAll = this._selectedItems && this.options && this._selectedItems.length  === this.options.length;

        this.processedListData = [];

        if (Array.isArray(this.options)) {
            this.options.forEach(el => {
                const isSearchMatch = !this.searchStr || el.text.toLowerCase().includes(this.searchStr.toLowerCase()) || el.metatext.toLowerCase().includes(this.searchStr.toLowerCase());
                const showItem = this.showOnlySelectedItems ? this.selectedItems.find(sl => sl.id === el.id) : true;
                this.processedListData.push({
                    key: el.id,
                    iconName: this.iconName,
                    text: el.text,
                    metaText: el.metatext,
                    isVisible: isSearchMatch && showItem? true: false,
                    isSearchMatch: isSearchMatch,
                    cssClass: isSearchMatch && showItem ? 'slds-listbox__item' : 'slds-listbox__item slds-hide'
                });
                //}
            });
        }
        //this.updateSelectedItemsInUI();
        //this.processedListData = [...this.processedListData];
    }

    // render(ev) {
    //     console.log('renderdTime', Date.now() - this.startTime);
    // }

    handleDone() {
        if (!this.reportValidity()) {
            // alert('Select at least one account');
            return;
        }
        this.isReadMode = true;
        this.showOnlySelectedItems = false;
        this.dispatchEvent(new CustomEvent('select', {detail: this.selectedItems}));
    }
    handleCancel() {
        //this.selectedItems = this.selectedItemsOld;
        this.processList(this.selectedItemsOld);
        this.isReadMode = true;
        this.selectAll = this.options.length === this.selectedItems.length;
    }

    handleEdit() {
        this.updateSelectedItemsInUI();
        this.isReadMode = false;
        this.searchStr = '';
        this.selectedItemsOld = [...this.selectedItems];
    }

    @api checkValidity() {
        // this.required = true;
        return this.selectedItems.length || !this.required;
    }

    @api reportValidity() {

        if (this.checkValidity()) {
            this.inpErrorMsg = '';
            this.inpCss = 'slds-combobox_container slds-has-selection';
            return true;
        }
        this.inpCss = 'slds-combobox_container slds-has-selection slds-has-error';
        this.inpErrorMsg = this.requiredErrorMessage;
        return false;
    }

    get searchInpCss() {
        return this.inpErrorMsg ? 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right slds-has-error'
            : 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right';
    }

    get noresults() {
        const hasVisibleRecords = this.processedListData.find(el => el.isSearchMatch === true);
        return !hasVisibleRecords && this.noResultsMsg;
    }

    handleInpChange(ev) {
        this.searchStr = ev.target.value || '';
        this.updateSelectedItemsList();
    }

    handleRemove(ev) {
        const toRemoveItemId = ev.detail.name;
        this._selectedItems = this.selectedItems.filter(el => el.id !== toRemoveItemId);
        this.updateSelectedItemsInUI();
    }

    @api labelAllSelected;
    @api labelItemsSelected;
    get displayText() {
        let label;

        if (this.selectedItems.length === 1) {
            label = this.selectedItems[0].text;
        } else if (this.selectedItems.length === this.options.length) {
            label = `${this.labelAllSelected} (${this.selectedItems.length})`;
        } else {
            label = `${this.selectedItems.length} ${this.labelItemsSelected}`;
        }

        return label;
    }

    handleSelectAllCbClick(ev) {
        this.selectAll = ev.target.checked;
        this.template.querySelectorAll('[data-group="listoptions"]').forEach(el => {
            el.checked = this.selectAll;
        });
        this.updateSelectedItemsList();
    }

    handleSelectAllLabelClick() {
        this.selectAll = !this.selectAll;
        this.template.querySelectorAll('[data-group="listoptions"]').forEach(el => {
            el.checked = this.selectAll;
        });
        this.updateSelectedItemsList();
    }

    handleListItemCbClick() {
        this.updateSelectedItemsList();
    }

    handleListItemLabelClick(ev) {
        const selItemId = ev.currentTarget.dataset.key;
        const rowElement = this.template.querySelector(`[data-group="listoptions"][data-key="${selItemId}"]`);
        rowElement.checked = !rowElement.checked;
        this.updateSelectedItemsList();
    }

    updateSelectedItemsList() {
        const selectedItems = [];
        this.template.querySelectorAll('[data-group="listoptions"]').forEach(aop => {
            if (aop.checked) {
                selectedItems.push({
                    text: aop.label, id: aop.value
                });
            }
        });
        this.processList(selectedItems);
    }

    updateSelectedItemsInUI() {
        this.template.querySelectorAll('[data-group="listoptions"]').forEach(aop => {
            aop.checked = this.selectedItems.find(sl => sl.id === aop.value);
        });

    }

    @track showOnlySelectedItems = false;
    handleFilterToggle(ev) {
        this.showOnlySelectedItems = ev.target.checked;
        this.updateSelectedItemsList();
    }
}