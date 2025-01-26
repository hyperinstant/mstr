# Music Universe
Music Universe is an exploration of human resonance through the meanings they put in three song arrangements.

## Pseudonymous nature
All accounts are pseudonymous.
Users provide their email to be able to restore a password and a nickname used in chats.
The system captures their timezone and registration IP address.

## Matching
Every user can create a triad: a three-song arrangement that represents something for them, which they think forms a whole through their internal sense of meaning and judgement. The key is that it's subjective.

Users with the same triad match with each other. Matches are always one-to-one. So if three users A, B and C have the same triad they form three pairs: AB, BC and AB.

The order of tracks in triads doesn't matter by default.
However, users can see the match score. A perfect score is when all tracks in the pair of triads are in the same position. Then when 2/3 are in the same positions, and lastly when tracks are in the opposite order.

### Perfect matching
Users can switch to perfect matching only on the triad level.
If a user turns on the setting to enable perfect matches only, then they unmatch with all their matches who provided songs in a different order than they did.

## Managing triads
Users can change tracks in their triad which will form a new active triad.

So if the user had a triad with songs `A, B, C` and then changed track `C` for `D` they created a new triad `A, B, D` and the previous triad `A, B, C` became inactive.

At this point all their connections for triad `A, B, C` also become inactive and they can't exchange messages with users with whom they matched through triad `A, B, C`.

If the user changes track `D` back for `C` they re-activate the triad `A, B, C`.

### Activation history
Even though triads capture song indexes as users provided them by default it doesn't affect the activation history.

So switching songs in the sequence of `A, B, C` -> `A, B, D` -> `E, B, D` -> `E, B, A` -> `C, B, A` will lead to the creation of four triads `[ A, B, C; A, B, D;  E, B, D; E, B, A; ]`  and activation of the triad `A, B, C` in the end.

Every triad activation/deactivation is captured, including indexes and the reason for change. So the sequence above will create the following log journal:

```
entry 1:
user_id <user_id>
triad_id <uuid of triad A,B,C>
track_1_id <uuid of track A>
track_2_id <uuid of track B>
track_3_id <uuid of track C>
action: :activated
reason: "Initial creation"
ts: <date time utc>

entry 2:
user_id <user_id>
triad_id <uuid of triad A,B,C>
track_1_id <uuid of track A>
track_2_id <uuid of track B>
track_3_id <uuid of track C>
action: :deactivated
reason: "Exploring new combinations"
ts: <date time utc>

entry 3:
triad_id <uuid of triad A,B,D>
track_1_id <uuid of track A>
track_2_id <uuid of track B>
track_3_id <uuid of track D>
action: :activated
reason: "Found better third track"
ts: <date time utc>

// ... last action
entry N:
triad_id <uuid of triad A,B,C>
track_1_id <uuid of track C>
track_2_id <uuid of track B>
track_3_id <uuid of track A>
action: :activated
reason: "Returning to original arrangement"
ts: <date time utc>
```

## Chats

### User pairs
Matched users can exchange messages as long they have two active matching triads.

### Triads
Triads themselves are chat rooms. For example, all users with triads `A, B, C` can chat with each other in the triad's room.

The triad room names are readable random identifiers in the format `{adjective}-{noun}-{number}`. Paid users can customize these room names.



## Premium Features
Paid users can:
- Have many active triads
- Create tetrads (4-song arrangements following the same matching rules)
- Customize triad room names
- Access detailed analytics about their triad evolution and matching patterns

## To Explore
Future considerations and potential features:
- Moderation (voting for moderators? silencing users? bans?)
- Private rooms (paid users only?)
- Allow users to create invitation-only triad rooms
- Implement private room discovery mechanics
- Consider implications for matching algorithms


### Enhanced Matching
Potential areas for expanding the matching system:
- Genre-based partial matching
- Temporal similarity (songs from same era/decade)
- Artist connection matching
- Mood/theme-based matching using audio features
- Cross-cultural musical pattern matching
