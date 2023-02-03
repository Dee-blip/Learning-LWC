({
    doInit: function(component, event, helper) {
        component.set('v.mycolumns', [
            {label: 'ORIGINAL CONTRACT ID', fieldName: 'Original_Contract_Id__c', type: 'text'},     
            {label: 'PARENT CONTRACT', fieldName: 'Parent_Contract__c', type: 'url',typeAttributes: {label: { fieldName: 'Parent_ContractName' }, target: '_blank'}},
            {label: 'ORDER ID', fieldName: 'Order_Id__c', type: 'text'},
            {label: 'CURRENCY', fieldName: 'Currency__c', type: 'text '},
            {label: 'CONTRACT TYPE', fieldName: 'Contract_Type__c', type: 'text '},
            {label: 'PARENT ACCOUNT NAME', fieldName: 'Parent_Account_Name__c', type: 'url',typeAttributes: {label: { fieldName: 'Parent_AccountName' }, target: '_blank'}},           
            {label: 'SOLUTION SET', fieldName: 'Solution_Set__c', type: 'text '},
            {label: 'EFFECTIVE END DATE', fieldName: 'Effective_Start_Date__c', type: 'date-local',typeAttributes:{month: "2-digit",day: "2-digit",year: "numeric"}},
            {label: 'EFFECTIVE START DATE', fieldName: 'Effective_End_Date__c', type: 'date',typeAttributes:{month: "2-digit",day: "2-digit",year: "numeric"}},
            {label: 'PRODUCTS', type: "button", typeAttributes: {
                label: {fieldName: 'Contract_Product_Count__c'},
                name: 'View',
                title: 'View',
                disabled: false,
                value: 'view',
                iconPosition: 'left',
                
                
            }}
        ]);
        
        component.set('v.productColumns', [
            {label: 'FORECAST PRODUCT NAME', fieldName: 'ProductName', type: 'text' },
            {label: 'CURRENCY CODE', fieldName: 'CurrencyIsoCode', type: 'text'},
            {label: 'BASELINE MONTHLY COMMIT', fieldName: 'Average_Renewal_Commit_MRR__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }}},
            {label: 'BASELINE MONTHLY USAGE', fieldName: 'Average_Renewal_Usage_MRR__c', type: 'currency',typeAttributes: { currencyCode: { fieldName: 'CurrencyIsoCode' }}},
        ]);
            
            
            helper.checkPermissionsAndLoadContracts(component,event,helper);      
            },
            
            dissociateContracts: function(component, event, helper) {
            var msg ='Disassociating will delete the selected Contract(s) and it’s Baseline Product(s). Do you want to continue??';
            if (!confirm(msg)) {            
            return false;
            } else {
            helper.dissociateContractsHelper(component, event, helper);
            }  
            },
            
            selectContract: function(component, event, helper) {
            var selectedRows = event.getParam('selectedRows');
            component.set('v.selectedContractList',JSON.parse(JSON.stringify(selectedRows)));
            
            },
            
            
            viewProducts : function(component, event, helper) {
            var rec = event.getParam('row');
            console.log(JSON.stringify(JSON.parse(JSON.stringify(rec)).Contract_Products__r ));
            var products = new Array();
            for(let c of JSON.parse(JSON.stringify(rec)).Contract_Products__r ){
            products.push(c);
            }
            
            component.set('v.productsForGlimpse',products);
            component.set('v.showProductModal',true);
            },
            hideMessage: function(component, event, helper) {
            
            component.set('v.message',null);
            
            },
            hideProductModal : function(component, event, helper) {
            component.set('v.showProductModal',false);
            }
            
            })