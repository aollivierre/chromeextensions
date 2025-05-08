# Chrome Web Store Submission Guide for Genesys Cloud Environment Badge

This guide provides specific recommendations to ensure your extension complies with Chrome Web Store policies and successfully passes review.

## Policy Violation Issues and Solutions

Based on your rejection notice, here are the likely policy violations and how to address them:

### 1. Privacy Policy Requirement

**Issue**: Extensions that access site content require a privacy policy, even if the data doesn't leave the browser.

**Solution**:
- Use the `privacy-policy.md` file we've created
- Host this file somewhere accessible online (company intranet, GitHub Pages, etc.)
- Provide the URL to this hosted file in the "Privacy Policy" section of your Chrome Web Store listing

### 2. Branding and Intellectual Property

**Issue**: Using "Genesys Cloud" in the extension name without explicit permission may violate intellectual property policies.

**Solutions** (choose one):
- Option A: Obtain written permission from Genesys to use their name in your extension
- Option B: Rename the extension to something generic like:
  - "Environment Indicator Badge"
  - "DR Environment Badge"
  - "Cloud Environment Indicator"
  - "[Your Company] Environment Badge"

### 3. Company-Specific Code Transparency

**Issue**: Hard-coded organization names (like "wawanesa") without clear disclosure might violate transparency requirements.

**Solutions**:
- In your store listing description, clearly state that the extension is designed for specific organizations
- Specify that the extension identifies environments based on organization names in the DOM
- Consider making the organization names configurable in a future version

### 4. Disclosure and Single Purpose

**Issue**: Extensions must clearly disclose all functionality.

**Solution**: Use this template for your description:

```
This extension helps users easily identify Genesys Cloud disaster recovery (DR) environments by displaying a color-coded visual badge at the top of the interface. It shows different colored badges for different environments:

- Red badge for DR environments
- Orange badge for TEST environments
- Blue badge for DEV environments
- No badge for PROD environments

The extension reads only the organization name displayed in the Genesys Cloud interface to determine the environment. All processing is done locally within your browser, and no data is transmitted externally.

This is an internal tool developed for specific organizations and is not affiliated with, endorsed by, or officially connected to Genesys Cloud.
```

## Submission Checklist

Before resubmitting:

✅ Update your Chrome Web Store listing with:
  - Clear description using the template above
  - Privacy policy URL (after hosting the policy online)
  - Detailed permission justification
  - "Single purpose" explanation that clearly states the extension's sole purpose

✅ Consider the branding issue and decide whether to:
  - Get permission from Genesys, or
  - Plan to rename the extension in a future update

✅ Make sure your screenshots clearly show the extension functionality

## Future Improvements (After Approval)

After getting approved, consider these improvements for future versions:

1. Make organization names configurable through extension options
2. Remove hard-coded organization names from the code
3. Consider a more generic extension name if you didn't receive permission from Genesys
4. Add proper attribution and disclaimers about Genesys trademarks

## Additional Resources

- [Chrome Web Store Program Policies](https://developer.chrome.com/docs/webstore/program-policies/)
- [Developer Terms of Service](https://developer.chrome.com/docs/webstore/terms/)
- [Branding Guidelines](https://developer.chrome.com/docs/webstore/branding/) 