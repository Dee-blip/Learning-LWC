({
    calculateDaysAgo: function(yourdate){
        var today  = new Date();
        var date1 = new Date(yourdate);
        var timeDiff = Math.abs(today.getTime() - date1.getTime());
        var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24));
        //console.log('-->'+diffDays);
        return diffDays;
    },
})