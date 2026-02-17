/**
 * Test class for TemperatureConverter.
 * Tests the conversion methods with various inputs.
 * Includes tests for normal conversions and null inputs.
 */
@isTest
public class TemperatureConverterTest {

    @isTest
    static void testCelsiusToFahrenheit() {
        // Test normal conversion
        Decimal result = TemperatureConverter.celsiusToFahrenheit(0);
        System.assertEquals(32, result, '0°C should be 32°F');

        // Test another value
        result = TemperatureConverter.celsiusToFahrenheit(100);
        System.assertEquals(212, result, '100°C should be 212°F');

        // Test null input
        result = TemperatureConverter.celsiusToFahrenheit(null);
        System.assertEquals(null, result, 'Null input should return null');
    }

    @isTest
    static void testFahrenheitToCelsius() {
        // Test normal conversion
        Decimal result = TemperatureConverter.fahrenheitToCelsius(32);
        System.assertEquals(0, result, '32°F should be 0°C');

        // Test another value
        result = TemperatureConverter.fahrenheitToCelsius(212);
        System.assertEquals(100, result, '212°F should be 100°C');

        // Test null input
        result = TemperatureConverter.fahrenheitToCelsius(null);
        System.assertEquals(null, result, 'Null input should return null');
    }
}