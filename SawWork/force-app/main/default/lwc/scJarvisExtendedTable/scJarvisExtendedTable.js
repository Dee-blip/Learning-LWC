import LightningDatatable from 'lightning/datatable';

import scJarvisRichText from './scJarvisRichText.html';
import scJarvisRelativeTime from './scJarvisRelativeTime';

export default class ScJarvisExtendedTable extends LightningDatatable  {
    static customTypes = {
        scRelativeTime: {
             template: scJarvisRelativeTime
        },
        scRichText:{
            template: scJarvisRichText
        }
        
   };

}