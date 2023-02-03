import {TAB_COLS} from "./sC_Akatec_Homepage_AllopenCases_Const";
const KEY_TABLE_COL_PROPS = 'all_open_cases_column_state';
const KEY_TABLE_SORTING_DETAILS = 'all_open_cases_column_sorting';

export const getMasterTableColumns = ()=>{
    try{
        let state = JSON.parse(localStorage.getItem(KEY_TABLE_COL_PROPS));
        return TAB_COLS.map(col => {
            if(col.name in state) Object.entries(state[col.name]).forEach(([key, val]) => {
                col[key] = val;
            });
            return col;
        });
    }catch (e) {
        console.warn(e);
        return TAB_COLS;
    }
}

export const saveMasterTableColumnState = (columns)=>{

    let existingStateStr = localStorage.getItem(KEY_TABLE_COL_PROPS);
    let existingState = {};
    const stripUnwantedProperties = (acc,col)=>{
        acc[col.name] = {
            initialWidth: col.initialWidth || 100
        }
        return acc;
    }
    //Check if localStorage data is corrupted. If corrupt, auto repair with default values
    if (existingStateStr){
        try{
            existingState = JSON.parse(existingStateStr);
        }catch (e) {
            console.info("'all_open_cases_column_state' localstorage has been reset with default values");
            existingState = TAB_COLS.reduce(stripUnwantedProperties,{});
        }
    }else{
        console.info("'all_open_cases_column_state' localstorage has been reset with default values");
        existingState = TAB_COLS.reduce(stripUnwantedProperties,{});
    }

    let modifiedState = columns.reduce(stripUnwantedProperties,{});

    Object.keys(modifiedState).forEach(colName => {
        existingState[colName] = modifiedState[colName];
    })
    localStorage.setItem(KEY_TABLE_COL_PROPS,JSON.stringify(existingState));
}

export const getSortingInfo = () => {
    try{
        let sortInfoStr = localStorage.getItem(KEY_TABLE_SORTING_DETAILS);
        return (sortInfoStr && JSON.parse(sortInfoStr)) || {};
    }catch (e) {
        return null;
    }
}

export const saveSortingInfo = async (sortedBy,sortDirection) => {
    localStorage.setItem(KEY_TABLE_SORTING_DETAILS, JSON.stringify({
        sortedBy,
        sortDirection
    }));
}