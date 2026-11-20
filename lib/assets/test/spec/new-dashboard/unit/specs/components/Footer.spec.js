import { shallowMount } from '@vue/test-utils';
import Footer from 'new-dashboard/components/Footer';

const $t = key => key;

describe('Footer.vue', () => {
  it('should not render the CARTO help footer', () => {
    const user = {
      account_type: 'free',
      organization: null,
      org_admin: false
    };
    const footerWrapper = shallowMount(Footer, {
      propsData: { user },
      mocks: { $t }
    });
    expect(footerWrapper.html()).not.toContain('HelpCenter');
    expect(footerWrapper.html()).not.toContain('carto.com/help');
  });
});
