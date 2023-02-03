/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 08-23-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   06-05-2021   apyati   Initial Version
**/
({
    getParameterByName: function(component, event, name) {
        name = name.replace(/[[]]/g, "\\$&");
        let url = window.location.href;
        let regex = new RegExp("[?&]" + name + "(=1.([^&#]*)|&|#|$)");
        let results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
})