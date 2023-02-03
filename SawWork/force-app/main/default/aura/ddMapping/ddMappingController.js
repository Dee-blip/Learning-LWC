({
    doInit: function(cmp, ev, hl) {
        let rtNames = [
            { label: 'AkaTec', value: 'Akatec'},
            { label: 'SOCC Product', value: 'SOCC_Case_Product'},
            // { label: 'SOCC Task Type', value: 'SOCC_Task_Type'},
            { label: 'Contract', value: 'Contract'},
            { label: 'Professional Service', value: 'Professional_Service'},
            { label: 'Revenue - PnP', value: 'Revenue_PnP'},
            { label: 'Revenue - non PnP', value: 'Revenue_non_PnP' }
        ];
        cmp.set('v.rtNames', rtNames);
        cmp.set('v.selRecordType', 'AkaTec');
    },
    handleOnSelect : function(cmp, ev, hl) {

        console.log('event --> ', ev);
        let currListView = cmp.get('v.selRecordType');
        let selListView = ev.getParam('name');
        // if (currListView !== selListView) {
        //     let rtNames = cmp.get('v.rtNames');
        //     console.log('rtNames --> ' , rtNames);
        //     rtNames.forEach((el) => {
        //         if(el.value === selListView) {
        //             currListView = el;
        //         }
        //     });
            console.log('currListView --> ' , currListView);

            cmp.set('v.selRecordType', selListView);

            $A.get('e.force:refreshView').fire(); 

        }
})