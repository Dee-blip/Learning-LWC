/**
**/
import { LightningElement, api, track } from 'lwc';
import getProductList from '@salesforce/apex/ChimeTriggerClass.getAllProducts';
export default class L2q_product_search extends LightningElement {

    @api showresults = false;
    @api fromwhere = '';
    @api placeholdertext = '';
    @api customstyle = '';
    @api selectedproducts = [];
    products = [];
    @track temp_products = [];
    isloading = false;

    @api poc=false;

    connectedCallback() {
        this.isloading = true;
        this.loadProducts();
    }

    handleFocus() {
        this.showresults = true;
    }

    handleBlur() {
        if (this.fromwhere === "detail") {
            this.showresults = false;
        }
    }

    loadProducts() {
        getProductList({poc : this.poc})
            .then(result => {
                result.forEach(el => {
                    if (this.selectedproducts.some(selectedProd => selectedProd.CHIME_Product__c === el.Id)) {
                        this.temp_products.push({ product: el, checked: true });
                        this.products.push({ product: el, checked: true });
                    }
                    else {
                        this.temp_products.push({ product: el, checked: false });
                        this.products.push({ product: el, checked: false });
                    }
                })
                this.temp_products.sort((a,b) => (a.product.Product_Name__c.toLowerCase() > b.product.Product_Name__c.toLowerCase()) ? 1 : ((b.product.Product_Name__c.toLowerCase() > a.product.Product_Name__c.toLowerCase()) ? -1 : 0));

                this.isloading = false;
            })
            .catch(error => {
                this.error = error;
            });
    }

    handleProductSearch(event) {
        this.showresults = true;
        let searchText = event.target.value;
        searchText = searchText.toLowerCase();
        if (this.products.length > 0) {
            let tempProducts = [];
            this.products.forEach(el => {
                let prodName = el.product.Product_Name__c;
                prodName = prodName.toLowerCase();
                if (prodName.includes(searchText)) {
                    tempProducts.push(el);
                }
            })

            tempProducts.sort((a,b) => (a.product.Product_Name__c.toLowerCase() > b.product.Product_Name__c.toLowerCase()) ? 1 : ((b.product.Product_Name__c.toLowerCase() > a.product.Product_Name__c.toLowerCase()) ? -1 : 0));
            this.temp_products = tempProducts;
        }
    }

    onProductSelect(event) {
        let tempProducts = [];
        this.products.forEach(el => {
            if (event.target.value === el.product.Id) {
                if (event.target.checked) {
                    el.checked = true;
                    el.product = el.product;
                    const selectedRecordEvent = new CustomEvent('selectedprod', {
                        detail: { record: el.product, action: 'add' }
                    });
                    this.dispatchEvent(selectedRecordEvent);
                }
                else {
                    el.checked = false;
                    el.product = el.product;
                    const selectedRecordEvent = new CustomEvent('selectedprod', {
                        detail: { record: el.product, action: 'remove' }
                    });
                    this.dispatchEvent(selectedRecordEvent);
                }
            }
            tempProducts.push(el);
        })
        tempProducts.sort((a,b) => (a.product.Product_Name__c.toLowerCase() > b.product.Product_Name__c.toLowerCase()) ? 1 : ((b.product.Product_Name__c.toLowerCase() > a.product.Product_Name__c.toLowerCase()) ? -1 : 0));
        this.temp_products = tempProducts;
    }

    @api handleProductRemoval(prodId) {
        let tempProducts = [];
        this.products.forEach(el => {
            if (prodId === el.product.Id) {
                el.checked = false;
                el.product = el.product;
            }
            tempProducts.push(el);
        })
        tempProducts.sort((a,b) => (a.product.Product_Name__c.toLowerCase() > b.product.Product_Name__c.toLowerCase()) ? 1 : ((b.product.Product_Name__c.toLowerCase() > a.product.Product_Name__c.toLowerCase()) ? -1 : 0));
        this.temp_products = tempProducts;
    }
    @api handleProductAddition(prodId) {
        //alert('handleProductAddition'+prodId);
        let tempProducts = [];
        console.log('prodId',prodId);
        console.log('temp_products',this.products);
        this.products.forEach(el => {
            if (prodId === el.product.Id) {
                el.checked = true;
                el.product = el.product;
                const selectedRecordEvent = new CustomEvent('selectedprod', {
                    detail: { record: el.product, action: 'add' }
                });
                this.dispatchEvent(selectedRecordEvent);
            }
            tempProducts.push(el);
        })
        tempProducts.sort((a,b) => (a.product.Product_Name__c.toLowerCase() > b.product.Product_Name__c.toLowerCase()) ? 1 : ((b.product.Product_Name__c.toLowerCase() > a.product.Product_Name__c.toLowerCase()) ? -1 : 0));
        console.log('tempProducts',tempProducts);
        this.temp_products = tempProducts;

    }
}