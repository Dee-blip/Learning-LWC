({
    getOpportunityList: function (cmp) {
        console.log('inside getOpportunityList');
        var action = cmp.get("c.getOpportunity");

        var ps = parseInt(cmp.get("v.pagesize"));
        var off = parseInt(cmp.get("v.offset"));

        action.setParams({
            "opptyId": cmp.get("v.recordId"),
            "pagesize": ps,
            "offset": off,
            "orderBy": cmp.get("v.orderBy") //added to update query at backend
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var listOfOpptys = response.getReturnValue();
            var opptys = cmp.get("v.listOfOpptys");
            if (cmp.isValid() && state === "SUCCESS") {
                cmp.set("v.listOfOpptys", opptys.concat(listOfOpptys));
                cmp.set("v.offset", off + ps);
            }
            opptys = cmp.get("v.listOfOpptys");
            if (opptys.length < 1) {
                cmp.set("v.noExistingOpptys", true);
                console.log('first : ', cmp.get("v.noExistingOpptys"));
                cmp.set("v.showLoadMore", false);
                var noOpp = document.getElementById("noOpp");
                if (noOpp) {
                    noOpp.style = "";
                    noOpp.className = "";
                }

            }
            if (listOfOpptys.length < 1) {
                cmp.set("v.hideLoadMore", true);
            }
            else {
                cmp.set("v.noExistingOpptys", false);
                cmp.set("v.hideLoadMore", false);
                cmp.set("v.showLoadMore", true);
            }

        });
        $A.enqueueAction(action);
    },

    getCurrentOpportunityAccountId: function (cmp, helper) {
        var action = cmp.get("c.getCurrentOpportunityAccountId");
        action.setParams({
            "opptyId": cmp.get("v.recordId")
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            var accID = response.getReturnValue();
            cmp.set("v.loadDone", true);
            if (cmp.isValid() && state === "SUCCESS") {
                cmp.set("v.current_opp_accID", accID);
            }
            if (accID && !accID.includes('null')) {
                cmp.set("v.locateAccHasNotBeenDone", false);
            }
            else {
                cmp.set("v.locateAccHasNotBeenDone", true);
            }
            helper.getOpportunityList(cmp); //SFDC-6799
        });
        $A.enqueueAction(action);


    },

    navigateToLocateAccountCmp: function (cmp) {
        console.log("inside navigateToLocateAccountCmp");
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:SF1_LocateAccountCmp",
            componentAttributes: {
                recordId: cmp.get("v.recordId")
            }
        });
        evt.fire();
    },

    create: function (cmp) {
        var action = cmp.get("c.getCreate");
        action.setParams({
            "oppId": cmp.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var message = response.getReturnValue();
            var navEvt = $A.get("e.force:navigateToSObject");

            if (cmp.isValid() && state === "SUCCESS" && message === 'success') {

                cmp.set("v.showError", false);
                navEvt.setParams({
                    "recordId": cmp.get("v.recordId"),
                    "slideDevName": 'detail'
                })
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
            }
            else if (cmp.isValid() && state === "SUCCESS" && message !== 'success') {
                cmp.set("v.message", message);
                cmp.set("v.showError", true);
                document.getElementById('message').style.display = "block";
                document.getElementById('message').scrollIntoView();


            }

        });
        $A.enqueueAction(action);
    }
})