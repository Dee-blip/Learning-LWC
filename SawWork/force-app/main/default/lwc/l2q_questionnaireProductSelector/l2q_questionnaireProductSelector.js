/**
*  @Date		:	April 2021
*  @Author		: 	Shivam Verma
*  @Description	:	Component implemented for Product selection for Chime Admin Application
*/

import { LightningElement, track } from 'lwc';
import getProductDataForAll from '@salesforce/apex/QuestionnaireController.getProductDataWithoutQuestionnaire';
import getProductDataForWithQuestionnaire from '@salesforce/apex/QuestionnaireController.getProductDataWithQuestionnaire';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import jQuery from '@salesforce/resourceUrl/jquery350';
import datatable from '@salesforce/resourceUrl/datatablebootstrap';
import { NavigationMixin } from 'lightning/navigation';

export default class L2q_questionnaireProductSelector extends NavigationMixin(LightningElement) {

    @track products;
    @track selectProductId;
    @track loadQuestionsWithoutQuestionnaire;
    
    connectedCallback() {
        this.loadQuestionsWithoutQuestionnaire = false;
        this.loadProductsTable();
    }

    loadProductsTable() {
        const thisRef = this;
        Promise.all([
            loadScript(this, jQuery),
            loadScript(this, datatable + '/dist/js/jquery.dataTables.min.js'),
            loadStyle(this, datatable + '/dist/css/jquery.dataTables.min.css')
        ])
        .then(() => {
            if (this.loadQuestionsWithoutQuestionnaire) {
                getProductDataForAll({})
                .then((result) => {
                    console.log("Scripts loaded");
                    // get the table tag reference from html template using class   
                    const table = this.template.querySelector('.productstable');
                    // set table headers 
                    const columnHeaders = ['Product Name' ,'Business Unit','Product Id', 'Questionnaire Action'];
                    
                    // create html table header part 
                    let columnHeaderHtml = '<thead> <tr>';
                    columnHeaders.forEach(function(header) {
                        columnHeaderHtml += '<th>' + header + '</th>';
                    });
                    columnHeaderHtml += '</tr></thead>';
                    table.innerHTML = columnHeaderHtml;
                    
                    // If a Datatable is already instantiated, delete the table 
                    if ( $.fn.DataTable.isDataTable(table) ) {
                        $(table).DataTable().destroy();
                    }

                    let oDataTable =  $(table).DataTable({
                        drawCallback: function(){
                            $('.paginate_button', this.api().table().container())          
                            .on('click', function(){
                                    $('.dt-create-questionnaire').each(function () {
                                        $(this).on('click','', function(evt){
                                            let $row = $(this).closest("tr");
                                            let $text = $row.find(".product").attr("hreflang");
                                            this.selectProductId = $text;
                                            //let showAdminObject = { productid: this.selectProductId };
                                            thisRef.navigateToQuestionnaire();
                                        });
                                    });
                            });       
                        }
                    });
                
                    // process all Opportunity records in a for loop and generate table row        
                    result.forEach(function(product) {
                        let tableRow = [];
                        let sUrl = '/lightning/r/PAC_Product_Catalog__c/' + product.Id + '/view'; 
                        tableRow.push('<a class="product" hreflang="'+product.Id+'" href="' + sUrl + '">' + product.Product_Name__c + '</a>');
                        tableRow.push(product.Business_Unit__c != undefined ? product.Business_Unit__c : '');
                        tableRow.push(product.Marketing_Product_Id__c != undefined ? product.Marketing_Product_Id__c : '');
                        tableRow.push('<button style="" class="dt-create-questionnaire" type="button">Create</button>');
                        oDataTable.row.add(tableRow);
                    }) 
                    // use DataTables plugin draw function to reflect your data changes on UI
                    oDataTable.draw();

                    $('.dt-create-questionnaire').each(function () {
                        $(this).on('click','', function(evt){
                            let $row = $(this).closest("tr");
                            let $text = $row.find(".product").attr("hreflang");
                            this.selectProductId = $text;
                            console.log("product id"+this.selectProductId);
                            console.log("Navigating to :"+this.selectProductId)
                            let showAdminObject = { productid: this.selectProductId };
                            this.dispatchEvent(
                                    new CustomEvent('showadmin',
                                                        {bubbles: true, 
                                                        composed: true, 
                                                        detail :showAdminObject}
                                                    )
                                    );
                        });
                    });

                    $('.dataTable').on('click','.dt-create-questionnaire', function(evt){
                        console.log("Buton clicked");
                    });

                    
                    $('.tablediv').click(function() {
                        console.log("table clicked");
                    });

                    $('.table').each(function () {
                        $(this).on('click','tr', function(evt){
                            console.log("table clicked");
                        });
                    });

                    $('.productstable tbody').on('click', 'tr', function () {
                        console.log("Inside each row clicked");
                        let data = oDataTable.row( this ).data();
                        let productId = data[0].substring(
                            data[0].lastIndexOf('hreflang="') + 10, 
                            data[0].lastIndexOf('" href')
                        );
                        console.log(productId);
                        console.log(data[0]);
                        this.selectProductId = productId;
                        console.log("Ready to navigate : "+this.selectProductId);
                        thisRef.navigateToQuestionnaire(this.selectProductId);
                    } );
                    
                })
                
            } else {
                console.log("Get products which have questions");
                getProductDataForWithQuestionnaire({})
                .then((result) => {
                    console.log("Scripts loaded");
                    // get the table tag reference from html template using class   
                    const table = this.template.querySelector('.productstable');
                    // set table headers 
                    const columnHeaders = ['Product Name' ,'Business Unit','Product Id', 'Questionnaire Action'];
                    
                    let columnHeaderHtml = '<thead> <tr>';
                    columnHeaders.forEach(function(header) {
                        columnHeaderHtml += '<th>' + header + '</th>';
                    });
                    columnHeaderHtml += '</tr></thead>';
                    table.innerHTML = columnHeaderHtml;
 
                    if ( $.fn.DataTable.isDataTable(table) ) {
                        $(table).DataTable().destroy();
                    }
                    
                    //  apply dataTable library to the table and store reference in a variable 
                    let oDataTable =  $(table).DataTable({
                        drawCallback: function(){
                            $('.paginate_button', this.api().table().container())          
                            .on('click', function(){
                                    $('.dt-create-questionnaire').each(function () {
                                        $(this).on('click','', function(evt){
                                            let $row = $(this).closest("tr");
                                            let $text = $row.find(".product").attr("hreflang");
                                            this.selectProductId = $text;
                                            console.log("product id"+this.selectProductId);
                                            console.log("Navigating to :"+this.selectProductId)
                                            let showAdminObject = { productid: this.selectProductId };
                                            thisRef.navigateToQuestionnaire();
                                        });
                                    });
                            });       
                        }
                    });
                
                    // process all Opportunity records in a for loop and generate table row        
                    result.forEach(function(product) {
                        let tableRow = [];
                        let sUrl = '/lightning/r/PAC_Product_Catalog__c/' + product.Id + '/view'; 
                        tableRow.push('<a class="product" hreflang="'+product.Id+'" href="' + sUrl + '">' + product.Product_Name__c + '</a>');
                        tableRow.push(product.Business_Unit__c != undefined ? product.Business_Unit__c : '');
                        tableRow.push(product.Marketing_Product_Id__c != undefined ? product.Marketing_Product_Id__c : '');
                        tableRow.push('<button style="" class="dt-create-questionnaire" type="button">Update</button>');
                        oDataTable.row.add(tableRow);
                    }) 
                    // use DataTables plugin draw function to reflect your data changes on UI
                    oDataTable.draw();

                    $('.dt-create-questionnaire').each(function () {
                        $(this).on('click','', function(evt){
                            let $row = $(this).closest("tr");
                            let $text = $row.find(".product").attr("hreflang");
                            this.selectProductId = $text;
                            console.log("product id"+this.selectProductId);
                            console.log("Navigating to :"+this.selectProductId)
                            let showAdminObject = { productid: this.selectProductId };
                            this.dispatchEvent(
                                    new CustomEvent('showadmin',
                                                        {bubbles: true, 
                                                        composed: true, 
                                                        detail :showAdminObject}
                                                    )
                                    );
                        });
                    });

                    $('.dataTable').on('click','.dt-create-questionnaire', function(evt){
                        console.log("Buton clicked");
                    });

                    
                    $('.tablediv').click(function() {
                        console.log("table clicked");
                    });

                    $('.table').each(function () {
                        $(this).on('click','tr', function(evt){
                            console.log("table clicked");
                        });
                    });

                    $('.productstable tbody').on('click', 'tr', function () {
                        console.log("Inside each row clicked");
                        let data = oDataTable.row( this ).data();
                        let productId = data[0].substring(
                            data[0].lastIndexOf('hreflang="') + 10, 
                            data[0].lastIndexOf('" href')
                        );
                        this.selectProductId = productId;
                        console.log("Ready to navigate : "+this.selectProductId);
                        thisRef.navigateToQuestionnaire(this.selectProductId);
                    } );
                    
                })
            }
        })
        .catch(error => {
            console.log(error);
            console.log("Error loading scripts");
        });
            
        
    }

    switchProductsType(event) {
        this.loadQuestionsWithoutQuestionnaire = !this.loadQuestionsWithoutQuestionnaire;
        this.loadProductsTable();
    }

    navigateToQuestionnaire(prodId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Chime_Questionnaire'
            },
            state: {
                c__productid: prodId,
                c__fromadmin: true
            }
        }).then(url => {
            window.location.href = url;
        });
    }
}