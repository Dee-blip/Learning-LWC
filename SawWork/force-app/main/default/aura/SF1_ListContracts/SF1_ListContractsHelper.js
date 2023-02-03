/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 08-18-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-19-2021   apyati   Initial Version
**/
(
    {
        isEmpty: function (val) {
            return (val ? false : true);
        },

        // var areEqual = string1.toUpperCase() === string2.toUpperCase();
        validateEvent: function (component, event) {

            var acc = event.getParam("acc");
            var opptyBaslinePicked = event.getParam("selection");
            var withBaseLineType, withContractChange;
            component.set("v.showContract", event.getParam("showContracts"));
            withBaseLineType = "Create Opportunity with Contract Baseline";
            withContractChange = "Create Contract Change Opportunity";
            //console.log('equals to opptyBaslineType? :' + opptyBaslineType  + '; withBaseLineType: ' withBaseLineType);
            if (!this.isEmpty(acc) && !this.isEmpty(opptyBaslinePicked) && (opptyBaslinePicked.toUpperCase() === withBaseLineType.toUpperCase() || opptyBaslinePicked.toUpperCase() === withContractChange.toUpperCase())) {
                console.log('qualifies');
                component.set("v.acct", acc);
                //this.refreshState(component);

                if (opptyBaslinePicked.toUpperCase() === withContractChange.toUpperCase()) {
                    this.queryRows(component, 0, '');
                    component.set("v.isContractChange", true);
                }
                else {
                    component.set("v.isContractChange", false);
                    component.set("v.doneLoading", true);
                    component.set("v.noContractsFound", false);
                }
            }
            else {
                console.log('does not qualify');
                component.set("v.doneLoading", false);
                // @todo:  Fire the even tot fold the Oppty List from HERE...
                this.fireContractChangeEvent(null,null, null, null);
            }

            console.log("opptyBaslinePicked" + opptyBaslinePicked);
            console.log("showContract" + component.get("v.showContract"));
            console.log("isContractChange" + component.get("v.isContractChange"));
            console.log("doneLoading" + component.get("v.doneLoading"));

        },

        queryRows: function (component, page, sOrder) {
            var recordset, errors;
            var action = component.get("c.getActiveContractsByAccIdPagination");
            //console.log("=== fields ===="+fields);
            var params = {
                "acc": component.get("v.acct"), "lim": component.get("v.pagelimit") || 10, "currentPage": page,
                "sortField": component.get("v.sortField"), "sortOrder": sOrder || "asc"
            };
            console.log(JSON.stringify(params));
            action.setParams(params);
            action.setCallback(this, function (response) {
                console.log(response.getState());
                if (response && response.getState() === "SUCCESS" && component.isValid()) {
                    recordset = response.getReturnValue();
                    console.log(JSON.stringify(recordset));
                    component.set("v.doneLoading", true); // should we move this outside of this function ? need to validate.


                        recordset.rows.forEach( rec=>{
                            rec.checked = false;
                        });

                       

                    component.set("v.contracts", recordset.rows);
                    component.set("v.resultsetsize", recordset.size);


                    if (this.isEmpty(recordset.rows) || this.isEmpty(recordset.size) || recordset.size < 1) {

                        component.set("v.noContractsFound", true);
                        console.log('inside resultsNOTFound');

                    } else {
                        console.log('inside resultsFound');
                        //component.set("v.doneLoading", true); 
                        component.set("v.noContractsFound", false);
                        this.setContractsMap(component);

                    }

                    // Clean up the stateVariables...
                    this.refreshState(component);
                    /* need to uncomment this.
                    */
                }
                else if (response.getState() === "ERROR") {
                    errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                } else {
                    console.log("Action State returned was: " + response.getState());
                }

            });
            $A.enqueueAction(action);

        },

        refreshState: function (component) {

            // Clean up the state variables...
            component.set("v.selectedContracts", []);

            // fire refrsh to dependent components.
            this.fireContractChangeEvent(null, null,null, null);

        },

        // setContractsMap1 : function(component, event) {

        //     var contractList =  component.get("v.contracts");
        //     var selectedContractIds = component.get("v.selectedContracts"); 
        //     // console.log("contractList=" + contractList);
        //     // console.log("selectedContractIds=" + selectedContractIds);

        //     if (!this.isEmpty(contractList) &&  !this.isEmpty(selectedContractIds)) {

        //         var contractsMap = {};
        //         for (var i in contractList){
        //             console.log('contract=' + contractList[i]);
        //             console.log('contracts.ocd:' + contractList[i].Id);
        //             contractsMap[contractList[i].Id]=contractList[i];
        //         }
        //         console.log('contractsMapsize=' + contractsMap.size + '; contractMap=' + JSON.stringify(contractsMap));
        //         component.set("v.contractsMap", contractsMap);
        //     }
        // },

        setContractsMap: function (component) {
            var contractsMap, i;
            var contractList = component.get("v.contracts");
            var selectedContractIds = component.get("v.selectedContracts");
            // console.log("contractList=" + contractList);
            // console.log("selectedContractIds=" + selectedContractIds);

            if (!this.isEmpty(contractList) && !this.isEmpty(selectedContractIds)) {

                contractsMap = {};

                for (i = 0; i < contractList.length; i++) {
                    console.log('contract=' + contractList[i]);
                    console.log('contracts.ocd:' + contractList[i].Id);
                    contractsMap[contractList[i].Id] = contractList[i];
                }
                console.log('contractsMapsize=' + contractsMap.size + '; contractMap=' + JSON.stringify(contractsMap));
                component.set("v.contractsMap", contractsMap);
            }
        },


        /*
        updateAllCheckboxeshelper: function (component, event) {
            var checked, inputs, i;
            checked = event.target.checked; //event.target.id event.target.name
            inputs = document.querySelectorAll("input[type='checkbox']"); 
            console.log('inputs',inputs);
            for (i = 0; i < inputs.length; i++) {
                inputs[i].checked = checked;
            }
        },
        */


        fireContractChangeEvent: function (acc, selectedContractProducts, selectedContracts, currencyMisMatch) {
            var appEvent;
            console.log("fireContractChangeEvent- onContractSelectionChange:currencyMisMatch=" + currencyMisMatch + '; selectedContractProducts=' + selectedContractProducts +'; selectedContracts=' + selectedContracts + '; acc=' + acc);

            appEvent = $A.get("e.c:onContractSelectionChange");
            appEvent.setParams({ "contracts": selectedContracts });
            appEvent.setParams({ "contractproducts": selectedContractProducts });
            appEvent.setParams({ "accountId": acc });
            appEvent.setParams({ "hasCurrencyMisMatch": currencyMisMatch });
            console.log(JSON.stringify(appEvent.getParams()));
            appEvent.fire();
        },

        getSortOrder: function (cmp, changeorder) {
            if (changeorder && changeorder === true) {
                if (cmp.get("v.ascDescVal") === "asc") {
                    cmp.set("v.ascDescVal", "desc");
                } else if (cmp.get("v.ascDescVal") === "desc") {
                    cmp.set("v.ascDescVal", "asc");
                } else {
                    cmp.set("v.ascDescVal", "desc");
                }
            }
            return cmp.get("v.ascDescVal");
        },


        setCurrencyMisMatch: function (component) {
            var selectedContractIds, currSet, i, cont;
            var contractsMap = component.get("v.contractsMap");
            //var contractList =  component.get("v.contracts");
            selectedContractIds = component.get("v.selectedContracts");
            console.log("conMap=" + contractsMap) + '; selectedContracts:' + selectedContractIds;
            currSet = new Set();

            if (!this.isEmpty(contractsMap) && !this.isEmpty(selectedContractIds)) {
                for (i = 0; i < selectedContractIds.length; i++) {
                    cont = contractsMap[selectedContractIds[i]];
                    currSet.add(cont.Currency__c);
                }

            }
            else if (selectedContractIds) {
                for (i = 0; i < selectedContractIds.length; i++) {
                    console.log('selectedContractIds[i].Contract.CurrencyIsoCode' + JSON.stringify(selectedContractIds[i]));
                    currSet.add(selectedContractIds[i].Contract.CurrencyIsoCode);
                }
                console.log('currSet=' + currSet.size + 'currSet=' + currSet.values().next().value);
                //console.log('currSet=' + currSet.size + 'currSet=' + currSe.values().next().value);

                if (currSet.size > 1) {
                    console.log('has Currency Mis match');
                    component.set("v.isContractCurrencyMismatch", true);
                } else {
                    console.log('has No Currency Mis-match');
                    component.set("v.isContractCurrencyMismatch", false);
                }
            }

        },

        updateCheckboxhelper: function (component, event) {
            var checked = event.target.checked; //event.target.id event.target.name
            var contractId = event.target.name;

            var flag = true;
            var i, tmp, index, removed, contracts, acc, contractproducts, currencyMisMatch, contractEvent;
            if (component.get("v.isContractChange")) {
                component.set("v.selectedContracts", []);

                let cons =  component.get("v.contracts");
                for (i = 0; i < cons.length; i++) {
                    if (cons[i].Id !== contractId) {
                        cons[i].checked =false;

                    }else{
                        cons[i].checked =true;
                    }
                }
                component.set("v.contracts",cons);

                /*
                console.log('@@ambica checkboxes bu aura id', component.find("contract-originalContractID"));
                var checkboxes = component.find("contract-originalContractID");

                if(checkboxes && !checkboxes.length) { // is an object, not an Array
                    checkboxes = [checkboxes]; // Make this an array
                }
                
                if(checkboxes) {
                    // Uncheck all boxes //
                    checkboxes.forEach(
                        function(cmp) {
                            console.log('@ambica cmpId'+cmp.get("v.id"));
                            console.log('@ambica cmp Name'+cmp.get("v.name"));
                            if(cmp.get("v.name") != contractId){
                                cmp.set("v.checked", false);
                            }
                        }
                    );
                } 
                */



            }

            tmp = component.get("v.selectedContracts"); // fetch the list of contractsSelected...

            //SFDC-7056
            for (i = 0; i < component.get("v.contracts").length; i++) {
                console.log("Value:" + component.get("v.contracts")[i].Is_Auto_Renew__c);
                console.log("Value1:" + component.get("v.contracts")[i].checked);
                if (component.get("v.contracts")[i].checked && component.get("v.contracts")[i].Is_Auto_Renew__c === "No") {
                    flag = false;
                    break;
                }
            }

            if (checked) {
                console.log("updateCheckBox checked");
                tmp.push(contractId);
            } else {
                console.log("updateCheckBox unchecked");
                index = tmp.indexOf(contractId);
                if (index > -1) {
                    removed = tmp.splice(index, 1);
                    console.log("removedId:" + removed);
                }
            }

            //alert('inside updateCheckbox...'+ event.target.name);
            //var tmp = component.get("v.selectedContracts");
            //tmp.push(contractId);
            console.log("selectedContracts:" + tmp);
            component.set("v.selectedContracts", tmp);

            //this.hasCurrencyMisMatch(component, event);
            this.setCurrencyMisMatch(component, event);

            // NOT WORKING
            //resultCmp = component.find("basline-select-result12");
            //console.log("resultCmp: " + resultCmp);
            //resultCmp.set("v.value", tmp);

            // fire the event...
            contracts = tmp;
            acc = component.get("v.acct");
            console.log('Inside listContracts, contracts:' + contracts + ', acc:' + acc + ', jsonContracts:' + JSON.stringify(tmp));
            contractproducts =[];
            currencyMisMatch = component.get("v.isContractCurrencyMismatch");
            console.log("fireContractChangeEvent:currencyMisMatch=" + currencyMisMatch);
            this.fireContractChangeEvent(acc.Id, contractproducts,tmp, currencyMisMatch); //JSON.stringify(tmp)
            //       var appEvent = $A.get("e.c:onContractSelectionChange");
            //       appEvent.setParams({"contracts" : JSON.stringify(tmp)});        
            // appEvent.setParams({"accountId" : acc});

            //       appEvent.fire();

            contractEvent = component.getEvent("onSelectContractChange");
            contractEvent.setParams({ "flag": flag });
            contractEvent.fire();
        },

        updateSelectedContractsHelper: function (component, event) {
            var acc, flag, contractProductIds, contractIds, currSet, i, currencyMisMatch, contractEvent;
            console.log('updateSelectedContractsHelper');

            const contractProducts = event.getParam('contractProducts');
            console.log('event.contractProducts' + JSON.stringify(contractProducts));
            component.set("v.selectedContracts", contractProducts);
            acc = component.get("v.acct");
            console.log('acc' + JSON.stringify(acc));
            flag = true;
            contractProductIds = [];
            contractIds = [];
            currSet = new Set();

            if (contractProducts) {
                for (i = 0; i < contractProducts.length; i++) {
                    console.log("Value:" + contractProducts[i].Contract.CurrencyIsoCode);
                    contractProductIds.push(contractProducts[i].Id);
                    contractIds.push(contractProducts[i].Contract.Id);
                    currSet.add(contractProducts[i].Contract.CurrencyIsoCode);
                    if (contractProducts[i].Contract.AutoRenew === "No") {
                        flag = false;
                    }

                }
                if (currSet.size > 1) {
                    component.set("v.isContractCurrencyMismatch", true);
                } else {
                    component.set("v.isContractCurrencyMismatch", false);
                }
            }
            console.log("onSelectContractChange:flag=" + flag);
            
            currencyMisMatch = component.get("v.isContractCurrencyMismatch");
            console.log("fireContractChangeEvent:currencyMisMatch=" + currencyMisMatch);
            this.fireContractChangeEvent(acc.Id, contractProductIds,contractIds, currencyMisMatch);
            
            contractEvent = component.getEvent("onSelectContractChange");
            contractEvent.setParams({ "flag": flag });
            contractEvent.fire();
            
            
        }
    })