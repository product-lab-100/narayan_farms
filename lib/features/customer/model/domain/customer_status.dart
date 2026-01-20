/// **CustomerStatus**
///
/// Represents the lifecycle state of a Customer.
///
/// **States**:
/// - `active`: Customer is in good standing and can perform actions.
/// - `inactive`: Customer account is dormant or disabled.
/// - `blocked`: Customer is restricted from using the platform.
enum CustomerStatus { active, inactive, blocked }
