/**
 * @description Service layer for Bundle_Option__c business logic.
 * Handles bundle data retrieval, option payload construction, validation, and CRUD operations.
 * Builds dynamic bundle configuration data for LWC consumption.
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class BundleOptionService {

    private static final String OTHER_FEATURE_ID = 'feature_other';
    private static final String OTHER_FEATURE_NAME = 'Other';

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Bundle_Product__c',
        'Default_Quantity__c',
        'Feature__c',
        'Is_Required__c',
        'Is_Selected__c',
        'Max_Quantity__c',
        'Min_Quantity__c',
        'Option_Product__c',
        'Option_Type__c',
        'Quantity_Editable__c',
        'Sort_Order__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Option_Type__c',
        'Sort_Order__c'
    };

    /**
     * @description Retrieves complete bundle configuration data including features and options.
     * Organizes options by feature and creates special "Other" feature for unassigned options.
     * Prepares data structure optimized for LWC consumption.
     * Bundle name is retrieved via LDS getRecord in LWC for better performance and caching.
     * @param bundleId The ID of the bundle product (Product2)
     * @return Map containing features list with structured option data
     * @throws BundleOptionException If bundleId is null or bundle product not found
     */
    public static Map<String, Object> getBundleData(Id bundleId) {
        if (bundleId == null) {
            throw new BundleOptionException('Bundle ID is required.');
        }

        Product2 bundleProduct = Product2DAO.getById(bundleId);
        if (bundleProduct == null) {
            throw new BundleOptionException('Bundle not found for the provided ID.');
        }

        List<Bundle_Feature__c> featureRecords = BundleFeatureDAO.getByProductId(bundleId);
        List<Bundle_Option__c> optionRecords = BundleOptionDAO.getByBundleProductId(bundleId);

        List<Map<String, Object>> featurePayloads = new List<Map<String, Object>>();
        Map<Id, Map<String, Object>> featurePayloadById = new Map<Id, Map<String, Object>>();

        for (Bundle_Feature__c featureRecord : featureRecords) {
            Map<String, Object> featurePayload = new Map<String, Object>{
                'Id' => String.valueOf(featureRecord.Id),
                'Name' => featureRecord.Name,
                'helpText' => featureRecord.Help_Text__c,
                'minOptions' => featureRecord.Min_Options__c,
                'maxOptions' => featureRecord.Max_Options__c,
                'options' => new List<Map<String, Object>>()
            };
            featurePayloads.add(featurePayload);
            featurePayloadById.put(featureRecord.Id, featurePayload);
        }

        List<Map<String, Object>> otherOptions = new List<Map<String, Object>>();

        for (Bundle_Option__c optionRecord : optionRecords) {
            Map<String, Object> optionPayload = buildOptionPayload(optionRecord);

            if (optionRecord.Feature__c != null && featurePayloadById.containsKey(optionRecord.Feature__c)) {
                List<Map<String, Object>> featureOptions = (List<Map<String, Object>>) featurePayloadById.get(optionRecord.Feature__c).get('options');
                featureOptions.add(optionPayload);
            } else {
                otherOptions.add(optionPayload);
            }
        }

        if (!otherOptions.isEmpty()) {
            featurePayloads.add(new Map<String, Object>{
                'Id' => OTHER_FEATURE_ID,
                'Name' => OTHER_FEATURE_NAME,
                'helpText' => System.Label.Bundle_Other_Feature_Description,
                'minOptions' => null,
                'maxOptions' => null,
                'options' => otherOptions
            });
        }

        return new Map<String, Object>{
            'features' => featurePayloads
        };
    }

    
    /**
     * @description Constructs a normalized option payload map for LWC consumption.
     * Uses only the data already loaded in the optionRecord (including relationships).
     * Handles null values with sensible defaults.
     * @param optionRecord The Bundle_Option__c record to transform
     * @return Map with keys: Id, Name, productCode, productName, description,
     *         defaultQuantity, minQuantity, maxQuantity, quantityEditable, isRequired, isSelected, optionType
     */
    private static Map<String, Object> buildOptionPayload(Bundle_Option__c optionRecord) {
        Product2 product = optionRecord.Option_Product__r;
        String optionProductId = optionRecord.Option_Product__c == null
            ? null
            : String.valueOf(optionRecord.Option_Product__c);
        
        return new Map<String, Object>{
            'Id' => String.valueOf(optionRecord.Id),
            'Name' => optionRecord.Name,
            'productId' => optionProductId,
            'productCode' => product?.ProductCode ?? '',
            'productName' => product?.Name ?? '',
            'description' => product?.Description ?? '',
            'defaultQuantity' => optionRecord.Default_Quantity__c ?? 0,
            'minQuantity' => optionRecord.Min_Quantity__c,
            'maxQuantity' => optionRecord.Max_Quantity__c,
            'quantityEditable' => optionRecord.Quantity_Editable__c ?? false,
            'isRequired' => optionRecord.Is_Required__c ?? false,
            'isSelected' => optionRecord.Is_Selected__c ?? false,
            'optionType' => optionRecord.Option_Type__c,
            'w' => product?.Width_cm__c,
            'h' => product?.Height_cm__c,
            'd' => product?.Depth_cm__c,
            'weight' => product?.Unit_Weight_Kg__c
        };
    }


    
    // ============================================================================
    // HELPER METHODS - Used by active methods above
    // ============================================================================
    
    /**
     * @description Saves a collection of Bundle_Option__c records (insert or update).
     * Validates all records before persistence and compares with persisted records to detect changes.
     * Only updates records that have actual field changes.
     * @param records List of Bundle_Option__c records to save
     * @param persistedRecordsById Map of existing records by ID for change detection
     * @return The same list of records that were saved
     * @throws ServiceException If records list is empty or required fields are missing
     */
   /* public static List<Bundle_Option__c> saveRecords(List<Bundle_Option__c> records, Map<Id, Bundle_Option__c> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Bundle_Option__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Bundle_Option__c>()
            : persistedRecordsById;
        List<Bundle_Option__c> recordsToInsert = new List<Bundle_Option__c>();
        List<Bundle_Option__c> recordsToUpdate = new List<Bundle_Option__c>();

        for (Bundle_Option__c recordItem : records) {
            validateRequiredFields(recordItem);
            if (recordItem.Id == null) {
                recordsToInsert.add(recordItem);
                continue;
            }

            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
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
*/
    /**
     * @description Deletes a collection of Bundle_Option__c records.
     * Validates that all records have IDs before deletion.
     * @param records List of Bundle_Option__c records to delete
     * @throws ServiceException If records list is empty or any record lacks an ID
     */
    /*public static void deleteRecords(List<Bundle_Option__c> records) {
        validateCollection(records);
        for (Bundle_Option__c recordItem : records) {
            if (recordItem.Id == null) {
                throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }*/


    /**
     * @description Validates that a record collection is not null and not empty.
     * @param records The collection to validate
     * @throws ServiceException If records is null or empty
     */
    /*private static void validateCollection(List<Bundle_Option__c> records) {
        if (records == null || records.isEmpty()) {
            throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }
*/

    /*
    /**
     * @description Collects all option product IDs from a list of bundle options.
     * Used to batch-query related Product2 records for efficiency.
     * @param optionRecords List of Bundle_Option__c records to extract IDs from
     * @return Set of Product2 IDs referenced by the options
     * /
    private static Set<Id> collectOptionProductIds(List<Bundle_Option__c> optionRecords) {
        Set<Id> optionProductIds = new Set<Id>();
        for (Bundle_Option__c optionRecord : optionRecords) {
            if (optionRecord.Option_Product__c != null) {
                optionProductIds.add(optionRecord.Option_Product__c);
            }
        }
        return optionProductIds;
    }
    */

    /**
     * @description Validates that all required fields are populated on a record.
     * Required fields: Option_Type__c, Sort_Order__c
     * @param recordItem The Bundle_Option__c record to validate
     * @throws BundleOptionException If any required field is missing or blank
     */
     /*private static void validateRequiredFields(Bundle_Option__c recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Bundle_Option__c.SObjectType.getDescribe().fields.getMap();
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
                throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Field_Required, new List<String>{ fieldLabel, getObjectLabel() }));
            }
        }
    }
*/
    /**
     * @description Compares a current record against its persisted version to detect field-level changes.
     * Only tracked fields are compared. Uses string value comparison to handle different data types.
     * @param currentRecord The current state of the Bundle_Option__c record
     * @param persistedRecord The previously saved state of the Bundle_Option__c record
     * @return True if any tracked field has changed, false otherwise
     */
    private static Boolean hasChanges(Bundle_Option__c currentRecord, Bundle_Option__c persistedRecord) {
        for (String fieldApiName : TRACKED_FIELDS) {
            if (valuesDiffer(currentRecord.get(fieldApiName), persistedRecord.get(fieldApiName))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Compares two values by converting them to strings.
     * Handles null values and type mismatches safely.
     * @param leftValue The first value to compare
     * @param rightValue The second value to compare
     * @return True if the string representations differ, false if they are the same
     */
    private static Boolean valuesDiffer(Object leftValue, Object rightValue) {
        return String.valueOf(leftValue) != String.valueOf(rightValue);
    }
    /**
     * @description Retrieves the label of the Bundle_Option__c SObject type.
     * @return The localized label for Bundle_Option__c
     */
     /*private static String getObjectLabel() {
        return Bundle_Option__c.SObjectType.getDescribe().getLabel();
    }
*/
    /**
     * @description Formats a label string with placeholder tokens.
     * Uses String.format() to replace placeholders with provided values.
     * @param labelValue The label template with placeholders
     * @param tokens List of values to substitute into the label
     * @return The formatted label string
     */
    /*private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }*/

    // ============================================================================
    // UNUSED METHODS - Commented for future use or reference
    // ============================================================================

    /*
    @description Returns the loaded record as-is.
    Placeholder method for future data transformation needs.
    
    public static Bundle_Option__c getLoadedRecord(Bundle_Option__c loadedRecord) {
        return loadedRecord;
    }
    */

    /*
    @description Safely returns a list of loaded records, handling null inputs.
    Placeholder method for future data transformation needs.
    
    public static List<Bundle_Option__c> getLoadedRecords(List<Bundle_Option__c> loadedRecords) {
        return loadedRecords == null ? new List<Bundle_Option__c>() : loadedRecords;
    }
    */

    // ============================================================================
    // RESERVED METHODS FOR FUTURE USE - Uncomment when trigger orchestration is needed
    // ============================================================================

    /*
    @description Trigger orchestration method for before insert events.
    Validates required fields before insert operation.
    
    public static void beforeInsert(List<Bundle_Option__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        for (Bundle_Option__c recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }
    */

    /*
    @description Trigger orchestration method for before update events.
    Validates record existence and required fields before update operation.
    
    public static void beforeUpdate(List<Bundle_Option__c> newRecords, Map<Id, Bundle_Option__c> oldRecordsById, Map<Id, Bundle_Option__c> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        Map<Id, Bundle_Option__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Bundle_Option__c>()
            : persistedRecordsById;
        for (Bundle_Option__c recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }
    */

    /*
    @description Trigger orchestration method for before delete events.
    Validates record IDs before delete operation.
    
    public static void beforeDelete(Map<Id, Bundle_Option__c> oldRecordsById, Map<Id, Bundle_Option__c> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }
        for (Bundle_Option__c recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new BundleOptionException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }
    */

    /*
    @description Trigger orchestration method for after insert events.
    Loads and processes records after insert operation.
    
    public static void afterInsert(List<Bundle_Option__c> newRecords) {
        getLoadedRecords(newRecords);
    }
    */

    /*
    @description Trigger orchestration method for after update events.
    Loads and processes records after update operation.
    
    public static void afterUpdate(List<Bundle_Option__c> newRecords, Map<Id, Bundle_Option__c> oldRecordsById, Map<Id, Bundle_Option__c> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }
    */

    /*
    @description Trigger orchestration method for after delete events.
    Placeholder for post-delete logic.
    
    public static void afterDelete(Map<Id, Bundle_Option__c> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }
    */
}
