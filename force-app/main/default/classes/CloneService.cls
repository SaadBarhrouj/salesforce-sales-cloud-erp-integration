/**
 * @description Generalized service for deep cloning Salesforce records along with selected child records.
 * Supports dynamic relationship discovery and field filtering for safe cloning.
 */
public with sharing class CloneService {

    /**
     * @description DTO to represent a child relationship and its records for the UI.
     */
    public class ChildRelationshipWrapper {
        @AuraEnabled public String id; // Unique ID for key-field in datatables
        @AuraEnabled public String relationshipName;
        @AuraEnabled public String childSObjectLabel;
        @AuraEnabled public String childSObjectApiName;
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public List<Map<String, String>> columns;

        /**
         * @description Constructor for ChildRelationshipWrapper.
         * @param relName The relationship name.
         * @param childDescribe The describe result for the child object.
         * @param recs The list of child records.
         */
        public ChildRelationshipWrapper(String relName, DescribeSObjectResult childDescribe, List<SObject> recs) {
            this.id = relName; 
            this.relationshipName = relName;
            this.childSObjectLabel = childDescribe.getLabel();
            this.childSObjectApiName = childDescribe.getName();
            this.records = recs;
            this.recordCount = recs.size();
            this.columns = new List<Map<String, String>>();
            
            for (SObjectField f : childDescribe.fields.getMap().values()) {
                DescribeFieldResult dfr = f.getDescribe();
                if (dfr.isNameField()) {
                    this.columns.add(new Map<String, String>{
                        'label' => dfr.getLabel(),
                        'fieldName' => dfr.getName(),
                        'type' => 'text'
                    });
                    break;
                }
            }
        }
    }

    /**
     * @description Retrieves related child records for a given record ID, organized by relationship.
     * @param recordId The ID of the parent record.
     * @return List of wrappers containing relationship metadata and records.
     */
    @AuraEnabled(cacheable=true)
    public static List<ChildRelationshipWrapper> getRelatedChildRecords(Id recordId) {
        List<ChildRelationshipWrapper> wrappers = new List<ChildRelationshipWrapper>();
        if (recordId == null) {
            return wrappers;
        }

        SObjectType parentType = recordId.getSObjectType();
        DescribeSObjectResult parentDescribe = parentType.getDescribe();

        for (ChildRelationship rel : parentDescribe.getChildRelationships()) {
            String relName = rel.getRelationshipName();
            if (String.isBlank(relName)) {
                continue;
            }

            SObjectType childType = rel.getChildSObject();
            DescribeSObjectResult childDescribe = childType.getDescribe();
            
            if (shouldIncludeRelationship(rel, childDescribe)) {
                List<SObject> records = queryChildRecords(recordId, rel, childDescribe);
                if (!records.isEmpty()) {
                    wrappers.add(new ChildRelationshipWrapper(relName, childDescribe, records));
                }
            }
        }
        return wrappers;
    }

    private static Boolean shouldIncludeRelationship(ChildRelationship rel, DescribeSObjectResult childDescribe) {
        return (rel.isCascadeDelete() || childDescribe.isCustom()) && childDescribe.isQueryable();
    }

    private static List<SObject> queryChildRecords(Id recordId, ChildRelationship rel, DescribeSObjectResult childDescribe) {
        String childName = childDescribe.getName();
        String lookupField = rel.getField().getDescribe().getName();
        String nameField = getNameField(childDescribe);

        String queryTemplate = 'SELECT {0} FROM {1} WHERE {2} = :recordId LIMIT 500';
        String fieldsStr = (nameField.equalsIgnoreCase('Id')) ? 'Id' : 'Id, ' + nameField;
        String query = String.format(queryTemplate, new List<String>{ fieldsStr, childName, lookupField });
        
        return Database.query(query);
    }

    private static String getNameField(DescribeSObjectResult childDescribe) {
        for (SObjectField f : childDescribe.fields.getMap().values()) {
            DescribeFieldResult dfr = f.getDescribe();
            if (dfr.isNameField()) {
                return dfr.getName();
            }
        }
        return 'Id';
    }

    /**
     * @description Clones a record and its selected children.
     * @param recordId The ID of the original parent record.
     * @param selectedIdsMap Map of Relationship Name -> List of Record IDs to clone.
     * @return Id of the newly created parent record.
     */
    @AuraEnabled
    public static Id cloneRecordWithChildren(Id recordId, Map<String, Object> selectedIdsMap) {
        try {
            SObjectType parentType = recordId.getSObjectType();
            String parentSObjName = parentType.getDescribe().getName();
            
            // 1. Query and Clone Parent
            String parentQuery = generateAllFieldsQuery(parentSObjName) + ' WHERE Id = :recordId';
            SObject originalParent = Database.query(parentQuery);
            SObject clonedParent = originalParent.clone(false, true, false, false);
            insert clonedParent;

            // 2. Process Children
            if (selectedIdsMap != null && !selectedIdsMap.isEmpty()) {
                cloneChildren(clonedParent.Id, parentType, selectedIdsMap);
            }

            return clonedParent.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void cloneChildren(Id newParentId, SObjectType parentType, Map<String, Object> selectedIdsMap) {
        List<SObject> childrenToInsert = new List<SObject>();
        DescribeSObjectResult parentDescribe = parentType.getDescribe();

        for (ChildRelationship rel : parentDescribe.getChildRelationships()) {
            String relName = rel.getRelationshipName();
            if (String.isNotBlank(relName) && selectedIdsMap.containsKey(relName)) {
                childrenToInsert.addAll(prepareClonedChildren(newParentId, rel, selectedIdsMap.get(relName)));
            }
        }

        if (!childrenToInsert.isEmpty()) {
            insert childrenToInsert;
        }
    }

    private static List<SObject> prepareClonedChildren(Id newParentId, ChildRelationship rel, Object selectedIdsObj) {
        List<SObject> clonedChildren = new List<SObject>();
        List<Id> childIds = convertToIdList(selectedIdsObj);
        
        if (childIds.isEmpty()) {
            return clonedChildren;
        }

        SObjectType childType = rel.getChildSObject();
        String childSObjName = childType.getDescribe().getName();
        String lookupField = rel.getField().getDescribe().getName();

        String childQuery = generateAllFieldsQuery(childSObjName) + ' WHERE Id IN :childIds';
        for (SObject originalChild : Database.query(childQuery)) {
            SObject clonedChild = originalChild.clone(false, true, false, false);
            clonedChild.put(lookupField, newParentId);
            clonedChildren.add(clonedChild);
        }
        return clonedChildren;
    }

    private static List<Id> convertToIdList(Object obj) {
        List<Id> ids = new List<Id>();
        if (obj instanceof List<Object>) {
            for (Object o : (List<Object>)obj) {
                ids.add((Id)o);
            }
        }
        return ids;
    }

    private static String generateAllFieldsQuery(String sObjName) {
        Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap();
        List<String> fields = new List<String>();
        for (SObjectField f : fieldMap.values()) {
            DescribeFieldResult dfr = f.getDescribe();
            if (dfr.isAccessible() && dfr.isCreateable()) {
                fields.add(dfr.getName());
            }
        }
        return 'SELECT ' + String.join(fields, ', ') + ' FROM ' + sObjName;
    }
}
