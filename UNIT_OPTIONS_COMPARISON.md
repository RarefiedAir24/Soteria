# Unit Options Comparison: Custom Build vs White-Label UIs

## The Two Options

### Option 1: Custom Build (API-Based)
**Link**: https://www.unit.co/docs/api/
- Full API access
- Build your own UI
- Complete control
- More engineering work

### Option 2: White-Label UIs (Pre-Built Components)
**Link**: https://www.unit.co/docs/white-label-uis/
- Pre-built UI components
- Faster to market
- Less engineering
- Still customizable

---

## Comparison for Goal-Based Savings

| Factor | Custom Build (API) | White-Label UIs |
|--------|-------------------|-----------------|
| **Goal-Specific Features** | ✅ Full control to build goal UI | ⚠️ Generic banking components |
| **Integration with Existing App** | ✅ Seamless integration | ⚠️ May need to embed components |
| **Customization** | ✅ Complete control | ⚠️ Limited to themes/colors |
| **Time to Market** | ⚠️ 4-6 weeks | ✅ 1-2 weeks |
| **Engineering Effort** | ⚠️ More work | ✅ Less work |
| **Goal Tagging/Organization** | ✅ Full API control | ❓ Unknown if supported |
| **Multi-User Goals** | ✅ Can build custom | ❓ May not support |
| **Cost** | $$ | $$ (similar) |

---

## Analysis for Soteria

### White-Label UIs Components Available:
- ✅ **Account** component - Shows account details
- ✅ **Activity** component - Shows transactions
- ✅ **ACH Credit/Debit** - Payment components
- ✅ **Application Form** - User onboarding
- ❓ **Goal-specific features** - Not clear if available

### Key Question:
**Do White-Label UIs support goal-based sub-accounts or goal tagging?**

**Likely Answer**: Probably NOT, because:
- Components are generic banking UI
- Designed for standard accounts, not goal-specific
- No mention of "goals" or "sub-accounts" in component list

---

## Recommendation

### **Choose Custom Build (API)** for Soteria

**Why:**

1. **Goal-Specific Needs**
   - You need goal-based accounts/sub-accounts
   - White-Label UIs are generic banking components
   - Custom Build gives you full control to build goal features

2. **Existing App Integration**
   - You already have goal UI in your app
   - White-Label UIs would require embedding external components
   - Custom Build lets you integrate seamlessly

3. **Multi-User Goals**
   - You need shared goal functionality
   - White-Label UIs likely don't support this
   - Custom Build lets you build exactly what you need

4. **Brand Consistency**
   - Your app has specific design (Rever colors, etc.)
   - White-Label UIs can be themed but may not match perfectly
   - Custom Build = complete design control

5. **Future Flexibility**
   - You may add more goal-specific features
   - Custom Build = unlimited flexibility
   - White-Label UIs = limited to what Unit provides

---

## When White-Label UIs Make Sense

White-Label UIs are great if you:
- Need generic banking features (accounts, transactions, payments)
- Want fastest time to market
- Don't need goal-specific features
- Are building a standard banking app

**But for goal-based savings, Custom Build is better.**

---

## Hybrid Approach (Optional)

You could potentially use:
- **White-Label UIs** for: Application form, basic account display
- **Custom Build API** for: Goal creation, goal-specific features, multi-user goals

**However**, this adds complexity. Better to pick one approach.

---

## Final Recommendation

### **Go with Custom Build (API)**

**Reasons:**
1. ✅ Goal-specific features require custom implementation
2. ✅ Better integration with existing Soteria app
3. ✅ Complete control over user experience
4. ✅ Can build multi-user goal features
5. ✅ Matches your brand perfectly
6. ✅ Future-proof for new features

**Timeline**: 4-6 weeks (worth it for the flexibility)

**Next Steps:**
1. Sign up for sandbox: https://app.s.unit.sh/
2. Explore Custom Build API: https://www.unit.co/docs/api/
3. Test account creation with goal tags
4. Build goal-specific UI in your app

---

## White-Label UIs Could Work If...

You're willing to:
- Use generic account components (not goal-specific)
- Potentially lose some goal features
- Accept less customization
- Trade flexibility for speed

**But for your use case, Custom Build is the clear winner.**

