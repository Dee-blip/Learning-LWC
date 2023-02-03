({
    init: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var cases = myPageRef.state.c__caseItems;
        var recId = myPageRef.state.c__siRecId;
        cmp.set("v.caseItems", cases);
        cmp.set("v.siRecId", recId);
    }
})