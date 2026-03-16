import { LightningElement } from 'lwc';
import { ILLUSTRATIONS, getIllustration } from 'c/cpqConstants';

/**
 * Header Test Component
 * Demonstrates the integration of page header with empty state
 */
export default class HeaderTest extends LightningElement {
  // Expose illustrations for template usage
  illustrations = ILLUSTRATIONS;

  /**
   * Handle Empty State CTA Button Click
   * @param {CustomEvent} event - Event from empty state component
   */
  handleEmptyStateAction(event) {
    console.log('Empty State CTA Button clicked', event.detail);
    // Add your navigation or action logic here
    // Example: navigate to create new opportunity
  }

  /**
   * Example method to change empty state illustration
   * @param {string} key - Illustration key from constants
   */
  changeIllustration(key) {
    const illustration = getIllustration(key);
    console.log('Changing illustration to:', illustration);
  }
}