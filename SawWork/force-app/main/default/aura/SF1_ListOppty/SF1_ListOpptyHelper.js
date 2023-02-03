({
    isEmpty : function(val) {
        return (val ? false : true);
    },

    validateOpptyChangeEvent : function (component, event) {

        var acc = event.getParam("acc");
        var opptyBaslinePicked = event.getParam("selection");
        var withBaseLineType = "Create Opportunity with Contract Baseline";
        var withContractChange = "Create Contract Change Opportunity";
        console.log("inside LIstOppty.validateOpptyChangeEvent... accId:" + acc + "; baselineSelection=" + opptyBaslinePicked);
        //console.log('inside getOpportunities: withBaseline=' + event.getParam("withBaseline"));
        
        var EditOppTab = component.find("noBaselineOpptysMessage"); 
        $A.util.removeClass(EditOppTab, 'slds-show');
        $A.util.addClass(EditOppTab, 'slds-hide');

        //console.log('equals to opptyBaslineType? :' + opptyBaslineType  + '; withBaseLineType: ' withBaseLineType);
        if (!this.isEmpty(acc) &&  !this.isEmpty(opptyBaslinePicked)) {
            if (opptyBaslinePicked.toUpperCase() === withBaseLineType.toUpperCase() || opptyBaslinePicked.toUpperCase() === withContractChange.toUpperCase()) {
                console.log('SKIPPING THE RUN...'); 
                component.set("v.doneLoading", false);
                //component.set("v.noOpportunitiesFound", false); 
            }
            else {
                console.log('does qualify for NonRenewalOppty Rendering...');
                //component.set("v.doneLoading", true);
                // @todo:  Fire the even tot fold the Oppty List from HERE...
                component.set("v.opptyMessageWithBaseline", false);
                component.set("v.noOpportunitiesFound", false);
                component.set("v.accountId", acc.Id);
                console.log('accID=' + component.get("v.accountId"));
                
                // @todo: Update this to new function...
                //this.getOpportunityByAccID(component, event, acc);
                this.queryWithoutBaselineRows(component, 0, '');

            }
            
        }
        
        if(!this.isEmpty(opptyBaslinePicked) && opptyBaslinePicked.toUpperCase() === withContractChange.toUpperCase()){
            component.set("v.isContractChange",true);
        }else{
            component.set("v.isContractChange",false);
        }

    },

    getOpportunityByAccID : function(component, event, acc) {

        console.log('inside getOpportunityByAccID: accountId=' + acc.Id); // + "; contractIDs=" + contractIds + "; param-contracts:" + event.getParam("contracts"));
        var action = component.get("c.getOpportunitiesByAccountIdPaginated");
        action.setParams({
            accountId: acc.Id,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.Opportunities", response.getReturnValue());
                console.log('inside getOpportunityByAccID list oppty=' + JSON.stringify(response.getReturnValue()));
                var opptys = component.get("v.Opportunities");
                //component.set("v.doneLoading", true);
                
                
                if((this.isEmpty(opptys)) || (!opptys.length>0)) {
                    console.log('oppty is empty.');
                    component.set("v.doneLoading", false);
                } else {
                    console.log('oppty not empty.');
                    component.set("v.doneLoading", true);                    
                }   
                console.log('vOpptys=' + opptys);
                console.log('opptylength=' + opptys.length);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Action State returned was: " + state);
            }
        });
        $A.enqueueAction(action);

    },

    queryWithoutBaselineRows : function(component, page, sOrder) {

        console.log('inside queryWithoutBaselineRows');

        var action = component.get("c.getOpportunitiesByAccountIdPaginated");
        var params = { "accountId": component.get("v.accountId"), "lim": component.get("v.pagelimit") || 10, "currentPage": page, 
                       "sortField" : component.get("v.sortField"), "sortOrder" :  sOrder || "asc" };
        console.log(JSON.stringify(params));
        action.setParams(params);
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getState());
            if (response && response.getState() === "SUCCESS" && component.isValid()) {

                var recordset = response.getReturnValue();
                console.log(JSON.stringify(recordset));
                component.set("v.Opportunities", recordset.rows);
                component.set("v.resultsetsize", recordset.size);
                component.set("v.doneLoading", true);

                // var opptys = recordset.rows;

                if((this.isEmpty(recordset.rows)) || (!recordset.size>0)) {
                    console.log('queryWithoutBaselineRows:oppty is empty.');
                    component.set("v.doneLoading", false);
                } else {
                    console.log('queryWithoutBaselineRows:oppty not empty.');
                    component.set("v.doneLoading", true);                    
                }   
                console.log('queryWithoutBaselineRows:vOpptys=' + recordset.rows);
                console.log('queryWithoutBaselineRows:opptylength=' + recordset.size);

            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Action State returned was: " + state);
            }
        });
        $A.enqueueAction(action);
    },

    validateWithBaseLineEvent : function (component, event, helper) {

       this.hideBaselineOpptyMessage(component);

        var accountId = event.getParam("accountId");
        var contractIds = event.getParam("contracts");


        component.set("v.opptyMessageWithBaseline", true);

        

        if (!this.isEmpty(accountId) &&  !this.isEmpty(contractIds) && (contractIds.length>0)) {

            console.log('NOT-Empty acc and contractIDs');

            component.set("v.accountId", accountId);
            component.set("v.contractIds", contractIds);
            // query Related Opptys...
            this.queryWithBaselineRows(component, 0, ''); 

            console.log('accId=' + accountId + '; contractIdsSize=' + contractIds.length + '; contractIDs=' + JSON.stringify(contractIds));

        } else {

            console.log('Empty acc and contractIDs');
            component.set("v.doneLoading", false);
            component.set("v.noOpportunitiesFound", true);
        }

    },

    hideBaselineOpptyMessage : function (component) {

        var tmp = component.find("noBaselineOpptysMessage"); 
        $A.util.removeClass(tmp, 'slds-show');
        $A.util.addClass(tmp, 'slds-hide');

    },

    queryWithBaselineRows : function (component, page, sOrder) {

        console.log('inside queryWithBaselineRows');
        var action = component.get("c.getOpportunitiesByContractIdsPaginated");
        var params = { "accountId": component.get("v.accountId"), "contractIds": component.get("v.contractIds"), "lim": component.get("v.pagelimit") || 10, "currentPage": page, 
        //var params = { "accountId": accountId, "contractIds": contractIds, "lim": component.get("v.pagelimit") || 10, "currentPage": page, 
                       "sortField" : component.get("v.sortField"), "sortOrder" :  sOrder || "asc" };
        console.log(JSON.stringify(params));
        action.setParams(params);
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getState());
            if (response && response.getState() === "SUCCESS" && component.isValid()) {
                
                var recordset = response.getReturnValue();
                console.log('queryWithBaselineRows=' + JSON.stringify(recordset));
                component.set("v.Opportunities", recordset.rows);
                component.set("v.resultsetsize", recordset.size);
                component.set("v.renewalContractsMap", recordset.rowsMap);
                component.set("v.doneLoading", true);

                this.validateState(component, recordset.rows, recordset.size);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Action State returned was: " + state);
            }
        });

        $A.enqueueAction(action);

    },

    validateState : function ( component,  opptys, opptySize) {

        // console.log('validateState:Opptys=' + opptys);
        // console.log('validateState:opptylength=' + opptys.length);
        // console.log('validateState:opptySize=' + opptySize);

        if((this.isEmpty(opptys)) || (!opptySize>0)) {
            
            console.log('validateState: Oppty is empty.');
            
            component.set("v.doneLoading", false);
            component.set("v.noOpportunitiesFound", true);

            var contractIds = component.get("v.contractIds");

            console.log('opptyFound?' + component.get("v.noOpportunitiesFound") + '; withBaseline?' + component.get("v.opptyMessageWithBaseline"));
            
            if (contractIds!=null && contractIds.length > 0) {
                
                // var contractIdsVar = event.getParam("contracts");
                // console.log('contractIds not empty but no Opptys found for:' + contractIds + '; contractIdsVar=' + contractIdsVar);

                var EditOppTab = component.find("noBaselineOpptysMessage"); 
                $A.util.removeClass(EditOppTab, 'slds-hide');
                $A.util.addClass(EditOppTab, 'slds-show');
            }

        } else {
            console.log('validateState:oppty not empty.');
            component.set("v.doneLoading", true);  
            component.set("v.noOpportunitiesFound", false);                  
        }
    },

    getSortOrder : function(cmp, changeorder) {
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

    getAssociatedContracts : function (component, event, opptyId) {
    
        var associatedContractsMap = component.get("v.renewalContractsMap");
        console.log('getAssociatedContracts=' + JSON.stringify(associatedContractsMap) + ':: associatedContractsMap=' + JSON.stringify(associatedContractsMap[opptyId]));
        return associatedContractsMap[opptyId];

    },
})