({
	parserInit : function(cmp, event, helper) {
        var cont = cmp.get('v.content');        
        console.log('Parsing Content: '+cont);
        if(cont)
        {
            helper.parseTextHelper(cmp,event,cont);
        }
        
	}
})