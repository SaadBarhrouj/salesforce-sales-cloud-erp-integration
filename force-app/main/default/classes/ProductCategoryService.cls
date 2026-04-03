/**
 * @description Service layer for ProductCategory business logic.
 * Orchestrates data access and provides business operations including hierarchy building
 * for sidebar category navigation filtered by opportunity parameters.
 */
public inherited sharing class ProductCategoryService {
    /**
     * @description Custom exception for ProductCategory service operations.
     */
    public class ServiceException extends Exception {}

    /*
    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'CatalogId',
        'Description',
        'IsNavigational',
        'Name',
        'ParentCategoryId',
        'SortOrder'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'CatalogId',
        'Name'
    };
    */
    /*    public static ProductCategory getLoadedRecord(ProductCategory loadedRecord) {
        return loadedRecord;
    }

    public static List<ProductCategory> getLoadedRecords(List<ProductCategory> loadedRecords) {
        return loadedRecords == null ? new List<ProductCategory>() : loadedRecords;
    }

    public static List<ProductCategory> saveRecords(List<ProductCategory> records, Map<Id, ProductCategory> persistedRecordsById) {
        validateCollection(records);

        Map<Id, ProductCategory> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCategory>()
            : persistedRecordsById;
        List<ProductCategory> recordsToInsert = new List<ProductCategory>();
        List<ProductCategory> recordsToUpdate = new List<ProductCategory>();

        for (ProductCategory recordItem : records) {
            validateRequiredFields(recordItem);
            if (recordItem.Id == null) {
                recordsToInsert.add(recordItem);
                continue;
            }

            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException('The requested ProductCategory record could not be found.');
            }

            if (hasChanges(recordItem, safePersistedRecordsById.get(recordItem.Id))) {
                recordsToUpdate.add(recordItem);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }

        return records;
    }

    public static void deleteRecords(List<ProductCategory> records) {
        validateCollection(records);
        for (ProductCategory recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException('An existing ProductCategory record Id is required for this operation.');
            }
        }
        delete records;
    }

    public static void beforeInsert(List<ProductCategory> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (ProductCategory recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<ProductCategory> newRecords, Map<Id, ProductCategory> oldRecordsById, Map<Id, ProductCategory> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, ProductCategory> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCategory>()
            : persistedRecordsById;

        for (ProductCategory recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException('An existing ProductCategory record Id is required for this operation.');
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException('The requested ProductCategory record could not be found.');
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, ProductCategory> oldRecordsById, Map<Id, ProductCategory> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (ProductCategory recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException('An existing ProductCategory record Id is required for this operation.');
            }
        }
    }

    public static void afterInsert(List<ProductCategory> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<ProductCategory> newRecords, Map<Id, ProductCategory> oldRecordsById, Map<Id, ProductCategory> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, ProductCategory> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<ProductCategory> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException('At least one ProductCategory record is required.');
        }
    }

    private static void validateRequiredFields(ProductCategory recordItem) {
        Map<String, Schema.SObjectField> fieldMap = ProductCategory.SObjectType.getDescribe().fields.getMap();
        for (String fieldApiName : REQUIRED_FIELDS) {
            Object rawValue = recordItem.get(fieldApiName);
            Boolean isMissing = rawValue == null;
            if (rawValue instanceof String) {
                isMissing = String.isBlank((String) rawValue);
            }
            if (isMissing) {
                String fieldLabel = fieldMap.containsKey(fieldApiName)
                    ? fieldMap.get(fieldApiName).getDescribe().getLabel()
                    : fieldApiName;
                throw new ServiceException(fieldLabel + ' is required for ProductCategory.');
            }
        }
    }

    private static Boolean hasChanges(ProductCategory currentRecord, ProductCategory persistedRecord) {
        for (String fieldApiName : TRACKED_FIELDS) {
            if (valuesDiffer(currentRecord.get(fieldApiName), persistedRecord.get(fieldApiName))) {
                return true;
            }
        }
        return false;
    }

    private static Boolean valuesDiffer(Object leftValue, Object rightValue) {
        return String.valueOf(leftValue) != String.valueOf(rightValue);
    }

    private static String getObjectLabel() {
        return ProductCategory.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
    */


    /**
     * @description Builds hierarchical category structure filtered by Opportunity ProductCatalog lookup and pricebook for sidebar navigation
     * @param opportunityId Salesforce Opportunity ID
     * @return List of category Maps with hierarchical structure; empty list if opportunity not found or ProductCatalog lookup is blank
     * @throws IllegalArgumentException if opportunityId is null
     */
    public static List<Map<String, Object>> buildSidebarHierarchyByOfferType(Id opportunityId) {
        Opportunity opp = OpportunityDAO.getById(opportunityId);
        if (opp == null) {
            return new List<Map<String, Object>>();
        }

        Id catalogId = opp.Offer_Type__c;
        if (catalogId == null) {
            return new List<Map<String, Object>>();
        }

        Id pricebookId = opp.Pricebook2Id;
        if (pricebookId == null) {
            return new List<Map<String, Object>>();
        }

        List<ProductCategory> allCategories = ProductCategoryDAO.getByCatalogId(catalogId);
        if (allCategories.isEmpty()) {
            return new List<Map<String, Object>>();
        }

        Set<Id> catIds = new Set<Id>();
        for (ProductCategory cat : allCategories) {
            catIds.add(cat.Id);
        }

        Map<Id, Integer> directCounts = ProductCategoryProductDAO.getProductCountForCategoriesByPricebook(catIds, pricebookId);

        return buildSidebarHierarchy(allCategories, directCounts);
    }

    /**
     * @description Organizes categories into a hierarchical tree structure, filtered by navigational flag and pricebook product availability
     * @param allCategories List of ProductCategory records
     * @param directCounts Map of product counts per category (filtered by pricebook)
     * @return List of Maps representing root categories with children where value > 0 (only categories with products in pricebook)
     */
    private static List<Map<String, Object>> buildSidebarHierarchy(List<ProductCategory> allCategories, Map<Id, Integer> directCounts) {
        if (allCategories == null || allCategories.isEmpty()) {
            return new List<Map<String, Object>>();
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        Map<Id, List<ProductCategory>> childrenByParentId = new Map<Id, List<ProductCategory>>();

        for (ProductCategory cat : allCategories) {
            if (cat.IsNavigational) {
                Id parentId = cat.ParentCategoryId;
                if (!childrenByParentId.containsKey(parentId)) {
                    childrenByParentId.put(parentId, new List<ProductCategory>());
                }
                childrenByParentId.get(parentId).add(cat);
            }
        }

        if (childrenByParentId.containsKey(null)) {
            for (ProductCategory rootCategory : childrenByParentId.get(null)) {
                Map<String, Object> rootMap = mapCategoryToObject(rootCategory, childrenByParentId, directCounts);
                if ((Integer)rootMap.get('value') > 0) {
                    result.add(rootMap);
                }
            }
        }

        return result;
    }

/**
     * Converts a ProductCategory to a Map with nested children structure (recursive).
     * Calculates total products for each category, including products in subcategories.
     * Only includes children with value > 0 (products in pricebook).
     * 
     * @description Recursively transforms a ProductCategory into a Map representation with child hierarchy
     * @param category The ProductCategory record to map
     * @param childrenByParentId Map of parent ID to list of child categories
     * @param directCounts Map of product counts per category
     * @return Map with 'id', 'label', 'value', and optional 'children' fields (only if value > 0)
     */
    private static Map<String, Object> mapCategoryToObject(
        ProductCategory category,
        Map<Id, List<ProductCategory>> childrenByParentId,
        Map<Id, Integer> directCounts
    ) {
        Map<String, Object> catMap = new Map<String, Object>();
        catMap.put('id', category.Id);
        catMap.put('label', category.Name);
        
        Integer totalProducts = directCounts.containsKey(category.Id) ? directCounts.get(category.Id) : 0;

        List<Map<String, Object>> children = new List<Map<String, Object>>();
        if (childrenByParentId.containsKey(category.Id)) {
            for (ProductCategory childCategory : childrenByParentId.get(category.Id)) {
                Map<String, Object> childMap = mapCategoryToObject(childCategory, childrenByParentId, directCounts);
                Integer childValue = (Integer)childMap.get('value');
                if (childValue > 0) {
                    children.add(childMap);
                    totalProducts += childValue;
                }
            }
        }
        
        catMap.put('value', totalProducts);

        if (!children.isEmpty()) {
            catMap.put('children', children);
        }

        return catMap;
    }
}