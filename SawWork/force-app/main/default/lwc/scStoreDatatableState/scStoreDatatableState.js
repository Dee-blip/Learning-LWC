const columnTypesToIgnore = ['action'];

/**
 * Utility method to handle null/invalid JSON strings
 * @param key {string} localStorage key
 * @return {{}}
 */
const getLocalStorageItem = (key) => {
    let storedStr = localStorage.getItem(key);
    let existingState;
    try{
        existingState = storedStr ? JSON.parse(storedStr) : {};
    }catch (e) {
        existingState = {};
    }
    return existingState || {};
}

const storeColumnState = async (tableName,columns = [], keyField, propertiesToStore = []) => {

    let key = tableName + '_column_state';
    let columnsToStore = columns.filter(col => !columnTypesToIgnore.includes(col.type));

    let colsWithoutKey = columnsToStore.filter(col => !col[keyField]);
    if (colsWithoutKey.length > 0) throw new Error(`Each columns should have unique ${keyField}' property: ${colsWithoutKey.map(col => col.label).join(', ')}`);

    let existingState = getLocalStorageItem(key);
    columnsToStore.forEach(col =>{
        existingState[col[keyField]] = Object.entries(col).reduce((acc, [field, val]) => {
            if (propertiesToStore.includes(field)) {
                acc[field] = val;
            }
            return acc;
        }, {});
    });

    localStorage.setItem(key,JSON.stringify(existingState));

}

const getColumnsState = (tableName) =>{
    let key = tableName +  '_column_state';
    return getLocalStorageItem(key);
}

const sortingStateKey = 'datatable_column_sorting';

const storeSortByColumn = async (tableName,sortedBy,sortDirection) => {
    let existingState = getLocalStorageItem(sortingStateKey);
    existingState[tableName] = {
        sortedBy,sortDirection
    };
    localStorage.setItem(sortingStateKey, JSON.stringify(existingState) );
}

const getSortByColumn = (tableName) => {
    let existingState = getLocalStorageItem(sortingStateKey);
    return existingState[tableName] || {};
}

export {storeColumnState,getColumnsState, storeSortByColumn, getSortByColumn}