/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 10-19-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-14-2021   apyati   Initial Version
**/
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getForecastProducts from '@salesforce/apex/l2qManageProductController.getForecastProducts';
export const KEYFIELD = 'Id';
export const DELAY = '300';
export default class L2qAddProducts extends LightningElement {
    @track gridColumns = [

        { 
            type: 'text',
            fieldName: 'ProductFamilyName',
            label: 'Product Family',
            initialWidth: 375,
        },
        {
            type: 'text',
            fieldName: 'ProductName',
            label: 'Product Name'
        }
    ];

    @track gridData = [];
    @track selectedRows = [];
    @track selectedData = [];
    @track expandedRows = [];
    @track slectedRowslst = [];
    @track expandedRowslst = [];
    @track searchKey = '';
    @track PROD_DATA = [];
    @track items = [];
    filteredRows = [];
    selectedRowdata = [];
    expandedRowdata = [];
    bypassOnRowSelection = false;



    @wire(getForecastProducts)
    productTreeData({ error, data }) {
        if (data) {
            let tempData = JSON.parse(JSON.stringify(data));
            let i = 1;
            let prodData = [];
            Object.keys(tempData).forEach(key => {
                let row = {
                    Id: i++ + '' + key,
                    ProductFamilyName: key,
                    selected: false
                }
                row._children = tempData[key];

                let prods = [];
                row._children.forEach(prod => {
                    let rowprod = {
                        Id: prod.Id,
                        ProductName: prod.Name,
                        ForecastId: prod.AKAM_Product_ID__c,
                        selected: false
                    }
                    prods.push(rowprod);
                });
                row._children = prods;
                prodData.push(row);
            });
            this.gridData = prodData;
            this.PROD_DATA = prodData;
            console.log(' wired gridData->', { ...this.gridData });

        } if (error) {
            console.error('error' + JSON.stringify(error));
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showToast('Error loading products',
                message,
                error,
                '',
                []);
        }

    }


    handleSave() {
        console.log('handleSave()');
        const evt = new CustomEvent('addproducts', {
            detail: this.selectedData
        });
        this.dispatchEvent(evt);
    }

    handleClose() {
        console.log('handleClose()');
        this.dispatchEvent(new CustomEvent('closeaddproducts'));

    }

    handleChange(event) {
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.detail.value;
        console.log('handleKeyChange() ' + searchKey);
        console.log('this.PROD_DATA ->', { ...this.PROD_DATA });
        console.log('this.selectedRows ->', { ...this.selectedRows });
        let expandRows = [];
        this.filteredRows = [];
        let temp_Data = JSON.parse(JSON.stringify(this.PROD_DATA));
        if (searchKey) {
            this.filtered = true;
            //console.log('search key');
            // console.log('temp_Data' + temp_Data.length);
            this.delayTimeout = setTimeout(() => {
                this.searchKey = searchKey;
                let filteredGridData = [];
                let filter_Data = temp_Data.filter(rec => JSON.stringify(rec).toLocaleLowerCase().includes(searchKey.toLocaleLowerCase()));
                // console.log('filter_Data' + filter_Data.length);
                filter_Data.forEach(row => {
                    // console.log('row_family' + row.ProductFamilyName);
                    // console.log('row_children' + row._children.length);
                    let filter_children = row._children.filter(rec => JSON.stringify(rec.ProductName).toLocaleLowerCase().includes(searchKey.toLocaleLowerCase()));
                    row._children = filter_children;
                    row._children.forEach(prod => {
                        expandRows.push(row.Id);
                        this.filteredRows.push(row.Id);
                        this.filteredRows.push(prod.Id);
                    });
                    if (row._children.length > 0) {
                        filteredGridData.push(row);
                    }
                    // console.log('filter_children' + row._children.length);
                });

                this.expandedRows = [...expandRows];
                // console.log('this.PROD_DATA ->', this.PROD_DATA.length);
                console.log('this.filteredRows ->', this.filteredRows.length);
                this.gridData = JSON.parse(JSON.stringify(filteredGridData));
            }, DELAY);

        } else {
            this.filtered = false;
            this.expandedRows = [...expandRows];
            console.log('search key blank ');
            //  console.log('this.PROD_DATA ->', this.PROD_DATA.length);
            console.log('this.filteredRows ->', this.filteredRows.length);
            this.gridData = [...this.PROD_DATA];
        }
        this.selectedRows = [...this.selectedRowdata];
        if (this.selectedRowdata.length > 0) {
            this.bypassOnRowSelection = true;
        }
    }

    updateSelectedRows(event) {

        console.log('updateSelectedRows()');
        console.log('bypassOnRowSelection' + this.bypassOnRowSelection);


        if (this.bypassOnRowSelection) {
            this.selectedRows = [...this.selectedRowdata];
            console.log('selectedRows' + this.selectedRows.length);
        }
        else {
            let filterrows = JSON.parse(JSON.stringify(this.filteredRows));
            console.log('filterrows' + filterrows.length);
            let newrows = event.detail.selectedRows;
            console.log('newrows' + newrows.length);
            let oldrows = JSON.parse(JSON.stringify(this.selectedRowdata));
            console.log('oldrows' + oldrows.length);
            let exprows = JSON.parse(JSON.stringify(this.expandedRowdata));
            console.log('exprows' + exprows.length);

            this.items = [];
            this.selectedRows = [];
            this.selectedData = [];
            this.selectedRowdata = [];
            let selectRows = [];

            //add selected rows
            newrows.forEach(row => {
                //console.log('new row' + row.Id);
                selectRows.push(row.Id);
            });

            if (filterrows.length === 0 && exprows.length === 0) {
                selectRows = [...oldrows];
            }
            else {
                // add rows selected before filtering /collapsing
                oldrows.forEach(rowId => {
                    // console.log('old rowId ' + rowId);

                    if (filterrows.length > 0 && !JSON.stringify(filterrows).includes(rowId) && !JSON.stringify(newrows).includes(rowId) && !JSON.stringify(selectRows).includes(rowId)) {
                        console.log('filter check ' + rowId);
                        selectRows.push(rowId);
                    }
                    else if (exprows.length > 0 && !JSON.stringify(exprows).includes(rowId) && !JSON.stringify(filterrows).includes(rowId) && !JSON.stringify(newrows).includes(rowId) && !JSON.stringify(selectRows).includes(rowId)) {
                        console.log('expand check ' + rowId);
                        selectRows.push(rowId);
                    }

                });
            }
            console.log('selectRows' + selectRows.length);
            let tempselectrows = [...new Set(selectRows)];
            console.log('tempselectrows' + tempselectrows.length);
            let tempdata = [];
            let temprows = [];
            let tempitems = [];

            if (tempselectrows.length > 0) {
                tempselectrows.forEach(rowId => {
                    this.PROD_DATA.forEach(family => {
                        /*
                        if (rowId === family.Id) {
                            // console.log('row' + JSON.stringify(rowId));
                            if (!temprows.includes(family.Id)) {
                                temprows.push(family.Id);
                                family._children.forEach(prod => {
                                    //console.log('prod' + JSON.stringify(prod));
                                    if (!temprows.includes(prod.Id)) {
                                        temprows.push(prod.Id);
                                        tempdata.push(prod);
                                        let item = {
                                            label: prod.ProductName,
                                            name: prod.Id,
                                        }
                                        tempitems.push(item);
                                    }
                                });
                            }
                        }
                        else { */
                        family._children.forEach(prod => {
                            if (rowId === prod.Id) {
                                if (!temprows.includes(family.Id)) {
                                    temprows.push(family.Id);
                                }
                                // console.log('prod' + JSON.stringify(prod));
                                if (!temprows.includes(prod.Id)) {
                                    temprows.push(prod.Id);
                                    tempdata.push(prod);
                                    let item = {
                                        label: prod.ProductName,
                                        name: prod.Id,
                                    }
                                    tempitems.push(item);
                                }

                            }
                        });
                        //}
                    });
                });
            }
            this.items = [...new Set(tempitems)];
            this.selectedRows = [...new Set(temprows)];
            this.selectedData = [...new Set(tempdata)];
            this.selectedRowdata = [...new Set(temprows)];
            //this.expandedRows = [...expandrows];
            console.log('items' + this.items.length);
            console.log('selectedRows' + this.selectedRows.length);
            console.log('selectedData' + this.selectedData.length);
            console.log('selectedRowdata' + this.selectedRowdata.length);
            console.log('expandedRowdata' + this.expandedRowdata.length);

        }

        this.bypassOnRowSelection = false;
        // console.log('selectRows' + JSON.stringify(this.selectedData));

    }

    showToast(title, message, variant, mode, messageData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                messageData: messageData,
                variant: variant,
                mode: mode
            }),
        );
    }

    handleItemRemove(event) {
        const name = event.detail.item.name;
        console.log('handleItemRemove', name);
        // console.log('items', this.items.length);

        const index = event.detail.index;
        this.items.splice(index, 1);

        console.log('items', this.items.length);


        let rows = [];
        let tempdata = [];
        this.items.forEach(item => {
            rows.push(item.name);
        });

        rows.forEach(rowId => {
            this.PROD_DATA.forEach(family => {
                family._children.forEach(prod => {
                    if (rowId === prod.Id) {
                        tempdata.push(prod);
                    }
                });
            });
        });

        this.selectedRowdata = [...rows];
        this.selectedRows = [...rows];
        this.selectedData = [...tempdata];

        console.log('selectedRows' + this.selectedRows.length);
        console.log('selectedData' + this.selectedData.length);
        console.log('selectedRowdata' + this.selectedRowdata.length);
    }


    onRowToggle(event) {



        let isexpand = event.detail.isExpanded;
        let expandId = event.detail.row.Id;
        let expandrows = [...this.expandedRowdata];
        console.log('isexpand' + isexpand)
        console.log('expandId' + expandId)

        console.log('expandrows' + expandrows.length)

        if (isexpand) {
            expandrows.push(expandId);
            console.log('expandrows add' + expandrows.length);

            if (this.selectedRowdata.length) {
                this.selectedRows = [...this.selectedRowdata];
            }
        }
        else if (!isexpand) {
            const index = expandrows.indexOf(expandId);
            console.log('index' + index);
            expandrows.splice(index, 1);
            console.log('expandrows remove' + expandrows.length);

            if (this.selectedRowdata.length > 0) {
                this.bypassOnRowSelection = true;
            }
        }

        let temprows = [];
        if (expandrows.length > 0) {
            expandrows.forEach(rowId => {
                this.PROD_DATA.forEach(family => {
                    if (rowId === family.Id) {
                        // console.log('row' + JSON.stringify(rowId));
                        temprows.push(family.Id);
                        family._children.forEach(prod => {
                            //console.log('prod' + JSON.stringify(prod));
                            temprows.push(prod.Id);
                        });
                    }
                });
            });
        }
        this.expandedRowdata = [...new Set(temprows)];
        console.log('expandedRowdata' + this.expandedRowdata.length);



    }

}