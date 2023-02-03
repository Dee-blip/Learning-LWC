({
	isEmpty : function(val) {
        return (val ? false : true);
    },

    updateAccount: function (cmp,evt) {
        
        // render this component & set the AccIds
        var context = evt.getParam("acc"); 
        //console.log("contractBaselineSelection:context=>" + context);
        cmp.set("v.acc", context);

        //acc = cmp.get("v.acc");
        //console.log('after accName=' + acc);
        //console.log("acc len:" + acc.length);

        if(this.isEmpty(context)){ //  || (!acc.length>0))
            console.log('acc is empty.');
            cmp.set("v.doneLoading", false);
            this.fireOpptyChangeEvent(null, null); // fire event in-case of deselection
        } else {
            console.log('acc not empty.');
            cmp.set("v.doneLoading", true);                    
        }   
        console.log('acc=' + context);

    },

    updateState: function (cmp, evt) {

        var selected = evt.getSource().get("v.label");
        console.log('selected=' + selected);
        // resultCmp = cmp.find("basline-select-result");
        // resultCmp.set("v.value", selected);
       
        cmp.set("v.selection", selected);

        //var withBaseLineType = "Create Opportunity with Contract Baseline"; // @todo: use gsmcutomsetting for this.
        //console.log('equals to opptyBaslineType? :' + opptyBaslineType  + '; withBaseLineType: ' withBaseLineType);
        // if ((selected.toUpperCase() === withBaseLineType.toUpperCase())) {
        //     console.log('THIS IS withBaseLine');
        //     //cmp.set("v.withBaseline", true);

        // }
        // else {
        //     console.log('THIS IS withOUTBaseLine');
        //     cmp.set("v.withBaseline", false);   
        // }
        
        // fire the event...
        var selection = cmp.get("v.selection");
        var acc = cmp.get("v.acc");
        //var withBaseLine = cmp.get("v.withBaseline");
        //console.log('ContractBaselineSelectionHelper.updateState acc:' + acc + '; selection:' + selection ); //+ '; withBaseline' + withBaseLine);
        
        this.fireOpptyChangeEvent(acc, selection); //, withBaseLine);
        //this.fireOpptyChangeEvent(cmp, evt);

    },

    fireOpptyChangeEvent: function (acc, selection) {

        var appEvent = $A.get("e.c:opportunityTypeChangeEvent");
        appEvent.setParams({ "selection" : selection });
        appEvent.setParams({ "acc" : acc });
        // appEvent.setParams({ "withBaseLine" : withBaseLine });

        // appEvent.setParams({ "selection" : cmp.get("v.selection") });
        // appEvent.setParams({ "acc" : cmp.get("v.acc") });
        //appEvent.setParams({ "withBaseLine" : cmp.get("v.withBaseline") });
        appEvent.fire();

    }

})