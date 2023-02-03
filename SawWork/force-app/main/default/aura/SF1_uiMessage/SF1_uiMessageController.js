({
    press : function(cmp){
        console.log('inside');
        var theMessage = cmp.getElement();
        var id='error uiMessage cSF1_uiMessage';
        var elem = document.getElementsByClassName(id)[0];
        return elem.parentNode.removeChild(elem);
       
	}
})