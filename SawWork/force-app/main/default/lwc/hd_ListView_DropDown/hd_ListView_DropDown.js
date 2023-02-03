import { LightningElement, api } from 'lwc';

export default class Hd_ListView_DropDown extends LightningElement {
    @api listViews = [];
    @api isOpen;
    // filteredListViews = listViews;
    searchString;
    listViewType = 'Incident';
    @api radioOptions;
    // @api radioOptions = [{ label: 'Incidents', value: 'Incident' }, { label: 'Service Requests', value: 'Service Request' }];

    get dropdownClass() {
        return (this.isOpen) ? 'panel open' : 'panel';
    }

    get searchFilteredListViews() {
        return (this.searchString) ? this.typeFilteredListViews()?.filter(listItem => listItem.Name.toLowerCase().includes(this.searchString.toLowerCase()) === true) : this.typeFilteredListViews();
    }

    typeFilteredListViews() {
        return ((this.listViewType === 'Incident') ? this.listViews?.filter(listItem => !listItem.Name.startsWith('SRM')) : this.listViews?.filter(listItem => listItem.Name.startsWith('SRM'))) ?? [];
    }

    renderedCallback() {
        this.template.querySelector('lightning-input').focus();
    }

    onListViewSelected(event) {
        let selectedItem = this.listViews.find(item => item.Id === event.currentTarget.dataset.id);
        this.dispatchEvent(new CustomEvent("listitemselected", {
            detail: {
                listView: selectedItem
            },
            bubbles: true,
            isComposed: true
        }));
        /* eslint-disable-next-line */
        this.isOpen = false;
    }

    handleOnchange(event) {
        this.searchString = event.detail.value;
    }

    handleRadioButtonChange(event) {
        this.listViewType = event.detail.value;
    }
}