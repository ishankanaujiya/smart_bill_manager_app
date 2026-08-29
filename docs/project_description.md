# Group Expense Splitter — Project Description

> A production-ready, cross-platform mobile application built with **Flutter** for managing shared expenses among friends, families, roommates, colleagues, travel groups, and other groups of people.

---

## Table of Contents

1. [Application Overview](#application-overview)
2. [Core Concept](#core-concept)
3. [User Accounts](#user-accounts)
4. [Groups](#groups)
5. [Adding Group Members](#adding-group-members)
6. [Hierarchical Group Member Visualization](#hierarchical-group-member-visualization)
7. [Expense Management](#expense-management)
8. [Automatic Expense Splitting](#automatic-expense-splitting)
9. [Payment Tracking](#payment-tracking)
10. [Group Financial Overview](#group-financial-overview)
11. [Expense History](#expense-history)
12. [Data Separation and Security](#data-separation-and-security)
13. [Application Architecture](#application-architecture)
14. [Production Requirements](#production-requirements)
15. [Design and User Experience](#design-and-user-experience)
16. [Future Extensibility](#future-extensibility)
17. [Core Product Principle](#core-product-principle)

---

## Application Overview

**Group Expense Splitter** is a production-ready cross-platform mobile application built with **Flutter** for managing shared expenses among friends, families, roommates, colleagues, travel groups, and other groups of people.

The primary purpose of the application is to make shared-expense management simple by automatically calculating individual financial responsibilities, tracking payments, and clearly showing outstanding balances within each group.

Instead of manually calculating who owes what, users can create a group, add registered members, create shared expenses, and allow the application to automatically determine each participant's share and payment status.

---

## Core Concept

The application's core financial relationship is:

```text
User
  ↓
Group
  ↓
Members
  ↓
Expenses
  ↓
Participants
  ↓
Individual Shares
  ↓
Payments
  ↓
Outstanding Balances
```

Every expense belongs to a specific group, and every group's financial information must remain logically separated from other groups.

---

## User Accounts

Users must be able to securely:

- Create an account
- Sign in
- Maintain their profile
- Be identified through their registered mobile number
- Search for other registered users using their mobile number

Only authenticated and authorized users should be able to access groups and financial information they are permitted to access.

---

## Groups

A user can create and manage multiple expense groups.

Examples:

- Friends
- Family
- Roommates
- Office Team
- Vacation/Trip
- Household Expenses

Each group acts as an independent financial boundary and maintains its own:

- Group information
- Members
- Expenses
- Expense participants
- Individual shares
- Payment records
- Outstanding balances
- Financial summary
- Expense history
- Settlement information

Data belonging to one group must not be incorrectly exposed to members or users outside that group.

---

## Adding Group Members

When creating or managing a group, users can add other registered users by searching for them using their registered mobile number.

The expected flow is:

```text
Create / Open Group
       ↓
Add Member
       ↓
Search by Mobile Number
       ↓
Find Registered User
       ↓
Select User
       ↓
Add User to Group
```

Only registered users should be eligible to be added through this mechanism.

---

## Hierarchical Group Member Visualization

A key part of the application is how group members are presented.

The members should **not be displayed only as a conventional vertical list**.

Instead, group members should be visually arranged in a **hierarchical/formation-based structure inspired by the way football applications visually arrange players on a field**.

The application should use the **concept of a football-style formation**, but it must **not look like a football or sports application**.

The visual treatment must follow the application's own design system and financial-product theme.

For example, conceptually:

```text
                    GROUP
                 Rs. 12,000
                      │
             ┌────────┴────────┐
             │                 │
          Member A          Member B
         Rs. 2,000          Rs. 2,000
            PAID               DUE
             │                 │
       ┌─────┴─────┐     ┌────┴─────┐
       │           │     │          │
    Member C    Member D Member E  Member F
    Rs. 2,000   Rs. 2,000 Rs.2,000 Rs.2,000
       PAID        DUE       PAID      DUE
```

The exact arrangement can be adapted based on the number of members and available screen space.

### Member Node

Each member should be represented as a visually distinct node/card containing relevant financial information such as:

- Profile/avatar
- Member name
- Amount to pay
- Payment status

For example:

```text
      ┌─────────────┐
      │    Avatar   │
      │             │
      └─────────────┘
        John Doe
       Rs. 2,500
          PAID
```

Payment states may include:

- **Paid**
- **Partially Paid**
- **Unpaid / Due**

If a member has partially paid, the UI should be able to communicate:

```text
Amount: Rs. 2,500
Paid: Rs. 1,000
Remaining: Rs. 1,500
Status: Partially Paid
```

The hierarchy represents the **financial relationship between the group and its members**, not a leadership or authority hierarchy.

The visual structure should therefore communicate:

```text
Group
  ↓
Members
  ↓
Financial Responsibility
```

and should not imply that one member is superior to another.

---

## Expense Management

Users can create expenses within a specific group.

An expense should support information such as:

- Expense title
- Total amount
- Description
- Expense creator/payer
- Participating members
- Individual share
- Payment status
- Payment records

Example:

```text
Group: Pokhara Trip

Expense: Dinner
Total: Rs. 5,000

Participants:
- User A
- User B
- User C
- User D
- User E
```

The application should automatically calculate each participant's share.

---

## Automatic Expense Splitting

Automatic expense calculation is one of the application's primary features.

For an equal split:

```text
Total Expense = Rs. 5,000
Participants = 5

Individual Share = Rs. 5,000 / 5
                 = Rs. 1,000
```

The calculation must be handled through centralized business logic rather than being independently implemented inside individual UI screens.

The architecture should also allow additional splitting methods to be introduced in the future without requiring major changes to the existing expense system.

Potential future methods include:

- Equal split
- Percentage split
- Exact amount split
- Shares-based split

---

## Payment Tracking

The application must track the payment state of each member's financial responsibility.

For every participant, the system should be able to determine:

- Total amount they are responsible for
- Amount already paid
- Remaining amount
- Payment status

Example:

| Member   |     Share |      Paid | Remaining | Status         |
| -------- | --------: | --------: | --------: | -------------- |
| Member A | Rs. 1,000 | Rs. 1,000 |     Rs. 0 | Paid           |
| Member B | Rs. 1,000 |   Rs. 500 |   Rs. 500 | Partially Paid |
| Member C | Rs. 1,000 |     Rs. 0 | Rs. 1,000 | Due            |

Payment information must remain associated with the correct group and expense.

---

## Group Financial Overview

Each group should provide a clear financial overview.

The overview should allow members to quickly understand:

- Total group expenses
- Total amount paid
- Total outstanding amount
- Individual member responsibilities
- Individual payment statuses
- Who has paid
- Who still owes money

A conceptual overview could be:

```text
Group Total
Rs. 10,000

Paid
Rs. 6,000

Outstanding
Rs. 4,000
```

This should be followed by the hierarchical member visualization so users can quickly identify individual responsibilities.

---

## Expense History

Each group maintains its own expense history.

Members should be able to review previously created expenses and understand:

- What the expense was
- When it was created
- Total amount
- Who participated
- Each participant's share
- Payment status
- Outstanding amount

Example:

```text
Pokhara Trip

Recent Expenses

Dinner          Rs. 5,000
Hotel           Rs. 8,000
Taxi            Rs. 1,500
Tickets         Rs. 6,000
```

Selecting an expense should provide its detailed financial breakdown.

---

## Data Separation and Security

Security and authorization are fundamental requirements.

Authentication alone must not be considered sufficient authorization.

A user should only be able to access a group and its financial information when they have appropriate permission to do so.

Conceptually:

```text
Authenticated User
       ↓
Is user a member of this group?
       ↓
      YES
       ↓
Access group's data
```

If the user is not authorized:

```text
Authenticated User
       ↓
Is user a member of this group?
       ↓
       NO
       ↓
Access denied
```

Database-level security/authorization rules must enforce this separation. Security should not depend only on hiding or restricting UI screens.

---

## Application Architecture

The application must be developed using a **scalable, maintainable, production-oriented architecture**.

There should be clear separation between:

```text
Presentation
     ↓
State Management
     ↓
Business Logic
     ↓
Repositories
     ↓
Data Sources
     ↓
Backend / Database
```

Shared application infrastructure should also be centralized, including:

- Design system
- Theme
- Constants
- Validation
- Formatting
- Error handling
- Utility functions
- Authentication
- Authorization
- Data access
- Common UI components

Business rules should not be duplicated across individual screens.

---

## Production Requirements

The application should be developed with production quality as a primary objective.

Important considerations include:

- Secure authentication
- Proper authorization
- Database security
- Input validation
- Reliable expense calculations
- Accurate payment tracking
- Error handling
- Data consistency
- Reliable synchronization
- Responsive UI
- Cross-platform consistency
- Maintainable code
- Scalable architecture
- Good application performance

Financial calculations must be deterministic and reliable because incorrect calculations can result in incorrect financial responsibilities.

---

## Design and User Experience

The application should have a **modern, professional, clean, and trustworthy financial-product interface**.

The hierarchical member visualization should be one of the application's distinctive UI elements, but it must remain consistent with the overall design system.

The football-style formation is used only as a **layout/visualization concept** for organizing members.

It should not introduce:

- Sports-themed colors
- Football graphics
- Sports terminology
- Unrelated decorative elements
- A sports-app visual language

The final experience should feel like a **professional expense-management application**.

All screens and components should follow a centralized design system to maintain visual consistency throughout the application.

---

## Future Extensibility

The initial architecture should allow future features to be introduced without major restructuring.

Potential future enhancements include:

- Expense settlement
- Direct member-to-member settlement
- Notifications
- Recurring expenses
- Detailed financial reports
- Transaction history
- Group invitations
- Multiple expense-splitting methods
- Advanced balance calculations
- Settlement optimization

These features do not all need to be implemented in the initial version, but the core architecture should not prevent them from being added later.

---

## Core Product Principle

The application should always make it easy for a user to answer three questions:

### 1. What did the group spend?

```text
Total Group Expenses
```

### 2. How much is each person responsible for?

```text
Member → Amount to Pay
```

### 3. Who has paid and who still owes?

```text
Member → Paid / Partially Paid / Due
```

The combination of **automatic calculation, hierarchical member visualization, payment tracking, and group-level financial separation** forms the core of Group Expense Splitter.
