$(document).ready(function() {
    // placehoder
    $('input, textarea').placeholder();

    // jqtransform: select, checkbox
    $('.select,th,td').jqTransform();

    // datatable
    $('.pane table').dataTable({
        sDom:'t',
        iDisplayLength:-1
        ,"aaSorting": [ [0,'desc'], [1,'desc'], [2,'desc'], [3,'desc'], [4,'desc'] ]
        ,fnDrawCallback:function() {
            //no sort empty row
            var tr = $(this).find('tr.no-sort');
            if(tr.length>0) {
                tr.detach();
                $(this).find('tbody').append(tr);
                $(this).find('tbody tr:odd').addClass('odd').removeClass('even');
                $(this).find('tbody tr:even').addClass('even').removeClass('odd');
            }
        }
    });

    // open cases checkbox
    $(".pane.large #table-cases .jqTransformCheckboxWrapper").click(function() {
        var a=$(this).find('a');
        if(a.parents('thead').length>0){
            a.parents('#table-cases').find("tbody tr td:first-child .jqTransformCheckboxWrapper a").each(function() {
                $(this).toggleClass("jqTransformChecked",a.hasClass('jqTransformChecked'));
                if(a.hasClass('jqTransformChecked')) {
                    $(this).siblings('input').attr("checked","checked");
                }else{
                    $(this).siblings('input').removeAttr("checked");
                }
            });
        }else{
            if(!a.hasClass('jqTransformChecked')){
                var h=a.parents('#table-cases').find("thead tr th:first-child .jqTransformCheckboxWrapper a");
                h.removeClass("jqTransformChecked");
                h.siblings('input').removeAttr("checked");
            }
        }
    });

    // open cases: switch
    $('.switch a').click(function() {
        $(this).siblings('a.active').removeClass('active');
        $(this).addClass('active');
        return false;
    });

    // call popup
    $('.call-header,.call-header .btn-expend').click(function() {
        $('.status').toggleClass('active');
        $(this).parents('.call').toggleClass('active');
        $(this).parents('.call').find('.select-status').jqTransform();
        return false;
    });

    // tip
    $('a[data-rel]').mouseenter(function() {
        $('.tip .tip-content').text($(this).attr('data-rel'));
        $('.tip').css({left:$(this).position().left-148+$(this).width()/2,top:$(this).position().top-$('.tip').height()+15}).show();
    });
    $('.btn-close').click(function() {
        $(this).parent().hide();
    });
})