({
    init: function(component, event, helper) {
        console.log('init search');
        var completeUrl = window.location.href;
        var searchText = completeUrl.replace(/.*searchText=([^&]*).*|(.*)/, '$1');
        console.log('Search text search');
        console.log(searchText);
        searchText = searchText.replace('+',' ');
        component.set('v.searchText',searchText);
    },
    
    formPress: function(component, event, helper) {
		if (event.keyCode === 13) {
			helper.handleClick(component, event, helper);
		}
	},
    
    handleSearch: function(component, event, helper) {
        helper.handleClick(component, event, helper);
    }
})