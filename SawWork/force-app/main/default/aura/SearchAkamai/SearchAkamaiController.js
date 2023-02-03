({
    handleKeyUpSearch: function (cmp, evt) {
        var url;
        var isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            url = 'https://search.akamai.com?source=salesforce&text='+cmp.find('search').get('v.value');
            window.open(url);
        }
    },
    handleClickSearch: function (cmp) {
        //var queryTerm = cmp.find('search').get('v.value');
        //alert('Searched for "' + queryTerm + '"!');
        var url = 'https://search.akamai.com?source=salesforce&text='+cmp.find('search').get('v.value');
        window.open(url);
    }
})