({

    /*
     * Executes the search server-side action when the c:InputLookupEvt is thrown
     */
  
    handleInputLookupEvt: function(component, event, helper){
        var searchString = event.getParam('searchString');
        // if(searchString.length == (searchString.indexOf(' ')+1)) {
        //     searchString = searchString.replace(' ', '');
        // }
        //console.log(searchString);
        // searchString = searchString.replace(/'space'/g, ' ');
        // console.log(searchString);
        if(searchString.length > 1) { // SFDC-3093
		    helper.searchAction(component, event.getParam('searchString'));
        }
    },


    /*
     *Loads the typeahead component after JS libraries are loaded
    */
    initTypeahead : function(component, event, helper){
        //first load the current value of the lookup field and then
        //creates the typeahead component
        helper.setSObjectIcon(component);
        helper.loadFirstValue(component);
    }



})