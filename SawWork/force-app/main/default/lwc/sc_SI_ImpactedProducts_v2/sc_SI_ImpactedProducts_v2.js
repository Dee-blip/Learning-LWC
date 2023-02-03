/* eslint-disable no-console */
/* eslint-disable no-alert */

import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

import getGridData from "@salesforce/apex/SC_SI_PageLayoutButton_Controllor.getGridData";
import saveImpactedProducts from "@salesforce/apex/SC_SI_PageLayoutButton_Controllor.saveImpactedProducts";
import userCheck from "@salesforce/apex/SC_SI_PageLayoutButton_Controllor.getButtonAccess";

export default class Sc_SI_Impacted_Products extends NavigationMixin(LightningElement) {
  // Service Incident Record Id
  @api recordId;

  // Check if the component is called from the sidebar
  @api fromSideSection;

  // Boolean property for the modal
  showModal;

  // Boolean properties for the Views
  selectView;
  defaultView;
  searchView;

  // Default View Tree Grid properties
  @track treeItems;
  @track gridData;
  @track expandedRows = [];
  @track tempjson = [];
  @track selectedRecords = [];
  @track defaultSelectedMap = new Map();
  @track collapsedProductIdsMap = new Map();

  // Select View Tree Grid properties
  searchKey;
  @track selRecs = [];
  @track expand = [];
  @track selectedJson;
  @track selectedData = [];
  @track selectedExpandedRows = [];
  @track selectTreeItems;
  @track selectExpandedRows;
  @track selectSelRecs;
  @track selSelectedRecords;
  @track selViewBackUp = [];
  firstSelectView = false;
  firstPrevView = false;
  @track collapsedSelectProdIds = [];
  fromSearch = false;
  num = 0;

  // variable to store only Selected records from the final page
  @track allSelectedRecords = [];

  // Search View Tree Grid properties
  @track searchTreeItems;
  @track searcExpandedRows;
  @track searchSelRecs;
  @track searchSelectedRecords = [];
  callFromSearch = false;
  @track searchViewBackUpMap = new Map();
  @track allSearchBackUp = new Map();
  @track allSearchMap = new Map();
  @track collapsedSearchProdIdsMap = new Map();

  //Toggle Properties
  @track fromToggle = false;
  @track expandedRec = [];
  fromExpanded = false;

  // spinner property
  showSpinner = false;

  // Grid Columns
  @track columns = [
    {
      type: "text",
      fieldName: "name",
      label: "Product Name"
    }
  ];

  // Get the Default View Records for IRAPT Users
  connectedCallback() {
    userCheck({ SIrecordId: this.recordId })
      .then(result => {
        let autorizeduser = JSON.parse(result);
        if (autorizeduser.isAddproductAuthorized) {
          this.showModal = true;
          this.defaultView = true;

          getGridData({})
            .then(result => {
              this.gridData = result;
              let limitedRecords = [];

              for (let i = 0; i <= 10; i++) {
                limitedRecords.push(result[i]);
                this.expand.push(result[i].productId);
                for (let j = 0; j < result[i].items.length; j++) {
                  this.expand.push(result[i].items[j].productId);
                  for (let k = 0; k < result[i].items[j].items.length; k++) {
                    this.expand.push(result[i].items[j].items[k].productId);
                  }
                }
              }

              this.expandedRows = this.expand;
              this.tempjson = JSON.parse(
                JSON.stringify(limitedRecords)
                  .split("items")
                  .join("_children")
              );
              this.treeItems = this.tempjson;
            })
            .catch(error => {
              console.log("error//" + JSON.stringify(error));
              console.log("error//" + error);
            });
        } else {
          const toastEvt = new ShowToastEvent({
            title: "Permission Required",
            message: "You are not authorized to add/edit Impacted Products.",
            variant: "Error",
            mode: "dismissible",
            duration: 5000
          });
          this.dispatchEvent(toastEvt);
          this.closeModal();
        }
      })
      .catch(error => {
        console.log("error//" + JSON.stringify(error));
        console.log("error//" + error);
      });
  }

  // Redirect to the SI Record and refresh Aura Component
  closeModal() {
    if (this.fromSideSection) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: this.recordId,
          objectApiName: "SC_SI_Service_Incident__c",
          actionName: "view"
        }
      });

    }
    else {
      this.showModal = false;
    }
    const refreshEvent = new CustomEvent("refreshAction", {});
    // Fire the custom event
    this.dispatchEvent(refreshEvent);

  }

  // Search functionality
  handleKeyUp(evt) {
    let searchedData = [];
    let searchedJson;
    let searchedExpandedRows = [];
    const isEnterKey = evt.keyCode === 13;
    this.searchKey = evt.target.value.toUpperCase();
    let prodIndex;
    let modIndex;

    if (
      (isEnterKey && this.searchKey.length >= 3) ||
      this.searchKey.length >= 3
    ) {
      this.defaultView = false;
      this.searchView = true;
      this.selectView = false;
      this.searchSelRecs = this.selectSelRecs;

      this.gridData.forEach(record => {
        if (record.name.toUpperCase().indexOf(this.searchKey) !== -1) {
          searchedData.push({
            name: record.name,
            productId: record.productId,
            entitledId: record.entitledId,
            items: []
          });
        }

        if (record.items !== "undefined" && record.items.length > 0) {
          record.items.forEach(module => {
            if (module.name.toUpperCase().indexOf(this.searchKey) !== -1) {
              prodIndex = searchedData.findIndex(
                item => item.productId === record.productId
              );

              if (prodIndex === -1) {
                searchedData.push({
                  name: record.name,
                  productId: record.productId,
                  entitledId: record.entitledId,
                  items: []
                });
                prodIndex = searchedData.findIndex(
                  item => item.productId === record.productId
                );
              }
              searchedData[prodIndex].items.push({
                name: module.name,
                productId: module.productId,
                parentProductName: module.parentProductName,
                parentProdId: module.parentProdId,
                entitledId: module.entitledId,
                items: []
              });
            }

            if (module.items !== "undefined" && module.items.length > 0) {
              module.items.forEach(subModule => {
                if (
                  subModule.name.toUpperCase().indexOf(this.searchKey) !== -1
                ) {
                  prodIndex = searchedData.findIndex(
                    item => item.productId === record.productId
                  );

                  if (prodIndex === -1) {
                    searchedData.push({
                      name: record.name,
                      productId: record.productId,
                      entitledId: record.entitledId,
                      items: []
                    });
                    prodIndex = searchedData.findIndex(
                      item => item.productId === record.productId
                    );
                  }

                  modIndex = searchedData[prodIndex].items.findIndex(
                    item => item.productId === module.productId
                  );

                  if (modIndex === -1) {
                    searchedData[prodIndex].items.push({
                      name: module.name,
                      productId: module.productId,
                      parentProductName: module.parentProductName,
                      parentProdId: module.parentProdId,
                      entitledId: module.entitledId,
                      items: []
                    });
                    modIndex = searchedData[prodIndex].items.findIndex(
                      item => item.productId === module.productId
                    );
                  }

                  searchedData[prodIndex].items[modIndex].items.push({
                    name: subModule.name,
                    productId: subModule.productId,
                    parentProductName: subModule.parentProductName,
                    parentProdId: subModule.parentProdId,
                    entitledId: subModule.entitledId,
                    parentModuleName: subModule.parentModuleName,
                    parentModProdId: subModule.parentModProdId,
                    items: []
                  });
                }
              });
            }
          });
        }
      });

      searchedData.forEach(data => {
        searchedExpandedRows.push(data.productId);
        if (data.items !== "undefined" && data.items.length > 0) {
          data.items.forEach(module => {
            searchedExpandedRows.push(module.productId);
            if (module.items !== "undefined" && module.items.length > 0) {
              module.items.forEach(subModule => {
                searchedExpandedRows.push(subModule.productId);
              });
            }
          });
        }
      });
      this.searcExpandedRows = searchedExpandedRows;

      searchedJson = JSON.parse(
        JSON.stringify(searchedData)
          .split("items")
          .join("_children")
      );
      this.searchTreeItems = searchedJson;

      this.searchSelRecs = [...this.allSearchMap.keys()];
      this.num = this.num + 1;
      this.callFromSearch = true;

      let checker = (arr, target) => target.every(v => arr.includes(v));

      if (checker(this.searcExpandedRows, this.searchSelRecs)) {
        this.callFromSearch = false;
      }

      this.fromSearch = true;
    }
    if (
      (isEnterKey && this.searchKey.length === 0) ||
      this.searchKey.length === 0
    ) {
      this.num = 0;
      this.defaultView = true;
      this.searchView = false;
      this.selectView = false;
      this.selRecs = [...this.defaultSelectedMap.keys()];
    }
  }

  // Row Selection Method for Default View Tree Grid
  showSelectedRecords() {
    var selectedRecordsProductIdList = [];

    this.selectedRecords = this.template.querySelector("lightning-tree-grid").getSelectedRows();

    this.selectedRecords.forEach(record => {
      selectedRecordsProductIdList.push(record.productId);
    });

    if (this.fromToggle && !this.fromExpanded) {
      [...this.defaultSelectedMap.keys()].forEach(record => {
        if (selectedRecordsProductIdList.indexOf(record) < 0) {
          this.collapsedProductIdsMap.set(
            record,
            this.defaultSelectedMap.get(record)
          );
        }
      });
    }

    if (!this.fromToggle && !this.fromExpanded) {
      this.defaultSelectedMap.clear();
      [...this.collapsedProductIdsMap.keys()].forEach(record => {
        if (![...this.defaultSelectedMap.keys()].includes(record))
          this.defaultSelectedMap.set(
            record,
            this.collapsedProductIdsMap.get(record)
          );
      });

      [...this.allSearchMap.keys()].forEach(record => {
        if (
          this.expand.includes(record) &&
          selectedRecordsProductIdList
            .concat([...this.collapsedProductIdsMap.keys()])
            .indexOf(record) < 0
        ) {
          this.allSearchMap.delete(record);
          this.allSearchBackUp.delete(record);
          this.searchViewBackUpMap.delete(record);
        }
      });
    }
    this.fromToggle = false;
    this.fromExpanded = false;

    this.selectedRecords.forEach(record => {
      if (![...this.defaultSelectedMap.keys()].includes(record.productId)) {
        this.defaultSelectedMap.set(record.productId, record);
      }
      if (![...this.allSearchMap.keys()].includes(record.productId)) {
        this.allSearchMap.set(record.productId, record);
        this.allSearchBackUp.set(record.productId, record);
        this.searchViewBackUpMap.set(record.productId, record);
      }
    });

  }

  // Row Selection Method for Search View Tree Grid
  showSearchSelectedRecs() {
    let selSearchedProductIds = [];

    this.searchSelectedRecords = this.template.querySelector("lightning-tree-grid").getSelectedRows();

    if (this.num === 1) {
      this.callFromSearch = false;
    }

    this.searchSelectedRecords.forEach(record => {
      selSearchedProductIds.push(record.productId);
    });

    if (this.fromSearch && !this.fromToggle && !this.fromExpanded) {
      this.collapsedSearchProdIdsMap.clear();
      this.fromSearch = false;
    }

    if (this.fromToggle && !this.fromExpanded) {
      [...this.searchViewBackUpMap.keys()].forEach(record => {
        if (selSearchedProductIds.indexOf(record) < 0) {
          this.collapsedSearchProdIdsMap.set(
            record,
            this.searchViewBackUpMap.get(record)
          );
        }
      });
    }

    if (!this.callFromSearch && !this.fromToggle && !this.fromExpanded) {
      this.searcExpandedRows.forEach(record => {
        if (
          selSearchedProductIds
            .concat([...this.collapsedSearchProdIdsMap.keys()])
            .indexOf(record) < 0
        ) {
          for (let k of this.allSearchBackUp.keys()) {
            if (k === record) this.allSearchBackUp.delete(k);
          }

          if (this.expand.includes(record)) {
            [...this.defaultSelectedMap.keys()].forEach(key => {
              if (key === record) this.defaultSelectedMap.delete(key);
            });
          }
        }
      });
    }

    if (!this.fromToggle && !this.callFromSearch && !this.fromExpanded) {
      this.searchViewBackUpMap.clear();
      [...this.collapsedSearchProdIdsMap.keys()].forEach(record => {
        if (![...this.searchViewBackUpMap.keys()].includes(record))
          this.searchViewBackUpMap.set(
            record,
            this.collapsedSearchProdIdsMap.get(record)
          );
      });
    }
    this.callFromSearch = false;

    this.fromToggle = false;
    this.fromExpanded = false;

    this.searchSelectedRecords.forEach(record => {
      if (![...this.searchViewBackUpMap.keys()].includes(record.productId)) {
        this.searchViewBackUpMap.set(record.productId, record);
      }

      if (![...this.allSearchBackUp.keys()].includes(record.productId)) {
        this.allSearchBackUp.set(record.productId, record);
      }

      if (
        this.expand.includes(record.productId) &&
        ![...this.defaultSelectedMap.keys()].includes(record.productId)
      ) {
        this.defaultSelectedMap.set(record.productId, record);
      }
    });

    this.allSearchMap = new Map([
      ...this.allSearchBackUp,
      ...this.searchViewBackUpMap
    ]);
  }

  // Row Selection Method for Select View Tree Grid

  showSelectSelectedRecs() {
    this.firstPrevView = false;
    let selectedProductIds = [];
    this.selSelectedRecords = this.template
      .querySelector("lightning-tree-grid")
      .getSelectedRows();

    this.selSelectedRecords.forEach(record => {
      selectedProductIds.push(record.productId);
    });

    if (this.fromToggle && !this.fromExpanded) {
      this.selViewBackUp.forEach(record => {
        if (selectedProductIds.indexOf(record) < 0) {
          this.collapsedSelectProdIds.push(record);
        }
      });
    }

    if (!this.fromToggle && !this.fromExpanded) {
      [...this.defaultSelectedMap.keys()].forEach(record => {
        if (
          selectedProductIds
            .concat(this.collapsedSelectProdIds)
            .indexOf(record) < 0
        ) {
          this.defaultSelectedMap.delete(record);
        }
      });

      [...this.allSearchMap.keys()].forEach(record => {
        if (
          selectedProductIds
            .concat(this.collapsedSelectProdIds)
            .indexOf(record) < 0
        ) {
          this.allSearchMap.delete(record);
          this.allSearchBackUp.delete(record);
          this.searchViewBackUpMap.delete(record);
        }
      });

      this.selViewBackUp = [];
      this.collapsedSelectProdIds.forEach(record => {
        if (!this.selViewBackUp.includes(record))
          this.selViewBackUp.push(record);
      });
    }
    this.fromToggle = false;

    this.selSelectedRecords.forEach(record => {
      if (!this.selViewBackUp.includes(record.productId)) {
        this.selViewBackUp.push(record.productId);

        if (
          this.expand.includes(record.productId) &&
          ![...this.defaultSelectedMap.keys()].includes(record.productId)
        ) {
          this.defaultSelectedMap.set(record.productId, record);
        }
        if (![...this.allSearchMap.keys()].includes(record.productId)) {
          this.allSearchMap.set(record.productId, record);
          this.allSearchBackUp.set(record.productId, record);
          this.searchViewBackUpMap.set(record.productId, record);
        }
      }
    });

    if (!this.fromToggle && !this.fromExpanded) {
      this.showSelectedView();
    }
  }

  // Shows all the records that are selected
  showSelectedView() {
    this.selectView = true;
    this.defaultView = false;
    this.searchView = false;
    /* let aa;*/
    // let bb;
    let selProdIndex;
    let selModIndex;

    let select = [];
    let sMap = new Map();
    let allSecRecs = [];

    this.selectedData = [];

    let tempSelectedRecs = [];

    allSecRecs = [...this.defaultSelectedMap.values()].concat([
      ...this.allSearchMap.values()
    ]);

    allSecRecs.forEach(record => {
      sMap.set(record.productId, record);
    });

    this.gridData.forEach(record => {
      if (sMap.has(record.productId)) {
        this.selectedData.push({
          name: record.name,
          productId: record.productId,
          entitledId: record.entitledId,
          items: []
        });
        select.push(record.productId);
        tempSelectedRecs.push(record);
      }

      if (record.items !== "undefined" && record.items.length > 0) {
        record.items.forEach(module => {
          if (sMap.has(module.productId)) {

            selProdIndex = this.selectedData.findIndex(
              item => item.productId === record.productId
            );

            if (selProdIndex === -1) {
              this.selectedData.push({
                name: record.name,
                productId: record.productId,
                entitledId: record.entitledId,
                items: []
              });
            }

            selProdIndex = this.selectedData.findIndex(
              item => item.productId === record.productId
            );
            this.selectedData[selProdIndex].items.push({
              name: module.name,
              productId: module.productId,
              parentProductName: module.parentProductName,
              parentProdId: module.parentProdId,
              entitledId: module.entitledId,
              items: []
            });
            select.push(module.productId);
            tempSelectedRecs.push(module);
          }

          if (module.items !== "undefined" && module.items.length > 0) {
            module.items.forEach(subModule => {
              if (sMap.has(subModule.productId)) {
                selProdIndex = this.selectedData.findIndex(
                  item => item.productId === record.productId
                );

                if (selProdIndex === -1) {
                  this.selectedData.push({
                    name: record.name,
                    productId: record.productId,
                    entitledId: record.entitledId,
                    items: []
                  });
                }

                selProdIndex = this.selectedData.findIndex(
                  item => item.productId === record.productId
                );
                selModIndex = this.selectedData[selProdIndex].items.findIndex(
                  item => item.productId === module.productId
                );

                if (selModIndex === -1) {
                  this.selectedData[selProdIndex].items.push({
                    name: module.name,
                    productId: module.productId,
                    parentProductName: module.parentProductName,
                    parentProdId: module.parentProdId,
                    entitledId: module.entitledId,
                    items: []
                  });
                }

                selModIndex = this.selectedData[selProdIndex].items.findIndex(
                  item => item.productId === module.productId
                );
                this.selectedData[selProdIndex].items[selModIndex].items.push({
                  name: subModule.name,
                  productId: subModule.productId,
                  parentProductName: subModule.parentProductName,
                  parentProdId: subModule.parentProdId,
                  entitledId: subModule.entitledId,
                  parentModuleName: subModule.parentModuleName,
                  parentModProdId: subModule.parentModProdId,
                  items: []
                });
                select.push(subModule.productId);
                tempSelectedRecs.push(subModule);
              }
            });
          }
        });
      }
    });

    this.selectedData.forEach(data => {
      this.selectedExpandedRows.push(data.productId);
      if (data.items !== "undefined" && data.items.length > 0) {
        data.items.forEach(module => {
          this.selectedExpandedRows.push(module.productId);
          if (module.items !== "undefined" && module.items.length > 0) {
            module.items.forEach(subModule => {
              this.selectedExpandedRows.push(subModule.productId);
            });
          }
        });
      }
    });
    this.selectExpandedRows = this.selectedExpandedRows;
    this.selectedJson = JSON.parse(
      JSON.stringify(this.selectedData)
        .split("items")
        .join("_children")
    );
    this.selectSelRecs = select;
    console.log("Selected Product Ids//" + this.selectSelRecs);
    this.allSelectedRecords = tempSelectedRecs;
    console.log('Selected Records//' + JSON.stringify(this.allSelectedRecords));
    this.selectTreeItems = this.selectedJson;
    this.firstSelectView = true;
    this.firstPrevView = true;
  }

  // Shows the Default View on clicking Previous
  showPrevious() {
    this.num = 0;
    // let selectedRecordss=this.template.querySelector('lightning-tree-grid').getSelectedRows();
    // console.log('selectedRecordss//'+JSON.stringify(selectedRecordss));

    this.selectView = false;
    this.defaultView = true;
    this.searchView = false;
    this.selRecs = [...this.defaultSelectedMap.keys()];
    this.collapsedProductIdsMap.clear();
  }

  handleRowToggle(event) {
    if (this.firstSelectView) {
      this.selectSelRecs.forEach(element => {
        if (!this.selViewBackUp.includes(element)) {
          this.selViewBackUp.push(element);
        }
      });
    }
    this.firstSelectView = false;

    if (event.detail.isExpanded) {
      this.fromExpanded = true;
      this.expandedRec = [];
      this.expandedRec.push(event.detail.row);

      this.expandedRec.forEach(record => {
        if (
          [...this.collapsedProductIdsMap.keys()].includes(record.productId)
        ) {
          this.collapsedProductIdsMap.delete(record.productId);
        }
        if (
          [...this.collapsedSearchProdIdsMap.keys()].includes(record.productId)
        ) {
          this.collapsedSearchProdIdsMap.delete(record.productId);
        }
        if (this.collapsedSelectProdIds.includes(record.productId)) {
          this.collapsedSelectProdIds = this.collapsedSelectProdIds.filter(
            n => {
              return n !== record.productId;
            }
          );
        }

        if (record._children !== "undefined" && record._children.length > 0) {
          record._children.forEach(module => {
            if (
              [...this.collapsedProductIdsMap.keys()].includes(module.productId)
            ) {
              this.collapsedProductIdsMap.delete(module.productId);
            }
            if (
              [...this.collapsedSearchProdIdsMap.keys()].includes(
                module.productId
              )
            ) {
              this.collapsedSearchProdIdsMap.delete(module.productId);
            }
            if (this.collapsedSelectProdIds.includes(module.productId)) {
              this.collapsedSelectProdIds = this.collapsedSelectProdIds.filter(
                n => {
                  return n !== module.productId;
                }
              );
            }

            if (
              module.hasOwnProperty("_children") &&
              module._children !== "undefined" &&
              module._children.length > 0
            ) {
              module._children.forEach(subModule => {
                if (
                  [...this.collapsedProductIdsMap.keys()].includes(
                    subModule.productId
                  )
                ) {
                  this.collapsedProductIdsMap.delete(subModule.productId);
                }
                if (
                  [...this.collapsedSearchProdIdsMap.keys()].includes(
                    subModule.productId
                  )
                ) {
                  this.collapsedSearchProdIdsMap.delete(subModule.productId);
                }
                if (this.collapsedSelectProdIds.includes(subModule.productId)) {
                  this.collapsedSelectProdIds = this.collapsedSelectProdIds.filter(
                    n => {
                      return n !== subModule.productId;
                    }
                  );
                }
              });
            }
          });
        }
      });


      this.selRecs = [...this.defaultSelectedMap.keys()];
      this.selectSelRecs = [...this.selViewBackUp];
      // this.searchSelRecs= [...this.allSearchKeys];
      this.searchSelRecs = [...this.allSearchMap.keys()];
    } 
    else {
      this.fromToggle = true;
      if (this.fromSearch === true) {
        this.fromSearch = false;
      }
    }
  }

  // To add eventlistner for click event on the Tree Grids
  renderedCallback() {
    let clickListener = this.template.querySelectorAll("lightning-tree-grid");
    clickListener.forEach(element => {
      element.addEventListener("click", this.handleClick.bind(this));
    });
  }
  // To handle click event on the Tree Grids
  handleClick() {
    this.fromExpanded = false;
  }

  // Creates the records for selected rows
  saveRecords() {
    if (this.selectedData.length > 0) {
      this.showSpinner = true;
      saveImpactedProducts({
        IncidentId: this.recordId,
        prodWrap: this.allSelectedRecords
      })
        .then(result => {

          if(result==='Success'){
          const toastEvt = new ShowToastEvent({
            title: "Success",
            message: "Impacted Products successfully added",
            variant: "Success",
            mode: "dismissible",
            duration: 5000
          });         
          this.dispatchEvent(toastEvt);
          this.closeModal();
        }
        else{
          const toastEvt = new ShowToastEvent({
            title: "Error",
            message: result,
            variant: "Error",
            mode: "dismissible",
            duration: 5000
          });         
          this.dispatchEvent(toastEvt);
        }
          this.showSpinner = false;
        })
        .catch(error => {
          this.showSpinner = false;
          console.log("error//" + JSON.stringify(error));
        });
    }
    else {
      const toastEvt = new ShowToastEvent({
        title: "Product Selection Required",
        message: "Select atleast one Product to add",
        variant: "Error",
        mode: "dismissible",
        duration: 3000
      });
      this.dispatchEvent(toastEvt);
    }
  }
}