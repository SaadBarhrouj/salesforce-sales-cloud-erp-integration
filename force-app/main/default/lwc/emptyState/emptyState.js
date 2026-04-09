/**
 * EmptyState Component
 * Reusable component to display empty states with illustrations
 * 
 * @example
 * <c-empty-state
 *   illustration-name="noresults:search"
 *   title="No Results"
 *   description="Try adjusting your search"
 *   size="small"
 *   show-cta-button="true"
 *   cta-label="Browse Products"
 *   onctabuttonclick={handleCta}>
 * </c-empty-state>
 */

import { LightningElement, api } from 'lwc';
import { dispatchCustomEvent } from 'c/cpqUtils';
import { EVENTS } from 'c/cpqConstants';

export default class EmptyState extends LightningElement {
  /**
   * Illustration name (e.g., 'noresults:search', 'cart:noitems')
   * @type {string}
   */
  @api illustrationName = 'noresults:unknown';

  /**
   * Title text for the empty state
   * @type {string}
   */
  @api title = 'No Results';

  /**
   * Description text for the empty state
   * @type {string}
   */
  @api description = '';

  /**
   * Size of the empty state: 'small', 'medium', or 'large'
   * @type {string}
   */
  @api size = 'medium';

  /**
   * Flag to show the CTA button
   * @type {boolean}
   */
  @api showCtaButton = false;

  /**
   * Label for the CTA button
   * @type {string}
   */
  @api ctaLabel = 'Action';

  /**
   * Variant of the CTA button: 'brand', 'neutral', 'destructive'
   * @type {string}
   */
  @api ctaVariant = 'brand';

  /**
   * Handle CTA Button Click
   * Dispatches custom event to parent component
   */
  handleCtaClick() {
    dispatchCustomEvent(this, EVENTS.CTA_CLICK, {
        timestamp: new Date().toISOString()
    });
  }
}