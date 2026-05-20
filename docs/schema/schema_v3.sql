## Table `accommodation`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  |
| `hotel_name` | `text` |  |
| `block_size` | `int4` |  Nullable |
| `rooms_remaining` | `int4` |  Nullable |
| `cutoff_date` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `activity_event`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `actor_id` | `uuid` |  Nullable |
| `action_type` | `text` |  |
| `object_type` | `text` |  Nullable |
| `object_id` | `uuid` |  Nullable |
| `metadata` | `jsonb` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `attendee_record`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  |
| `person_id` | `uuid` |  |
| `event_role` | `text` |  Nullable |
| `rsvp_status` | `text` |  Nullable |
| `rsvp_at` | `timestamptz` |  Nullable |
| `meal_preference` | `text` |  Nullable |
| `dietary_restrictions` | `text` |  Nullable |
| `tshirt_size` | `text` |  Nullable |
| `table_assignment` | `text` |  Nullable |
| `payment_status` | `text` |  Nullable |
| `plus_one_count` | `int4` |  Nullable |
| `waitlist_position` | `int4` |  Nullable |

## Table `billing_interval`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `value` | `text` |  Unique |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `branding`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  Nullable |
| `logo_url` | `text` |  Nullable |
| `mascot_url` | `text` |  Nullable |
| `hero_image_url` | `text` |  Nullable |
| `primary_color` | `text` |  Nullable |
| `secondary_color` | `text` |  Nullable |
| `primary_color_dark` | `text` |  Nullable |
| `font_choice` | `text` |  Nullable |
| `active_from` | `timestamptz` |  Nullable |
| `active_to` | `timestamptz` |  Nullable |
| `org_group_id` | `uuid` |  Nullable |

## Table `communication`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  Nullable |
| `event_id` | `uuid` |  Nullable |
| `sender_id` | `uuid` |  Nullable |
| `channel` | `text` |  Nullable |
| `audience` | `text` |  Nullable |
| `subject` | `text` |  Nullable |
| `body` | `text` |  Nullable |
| `sent_at` | `timestamptz` |  Nullable |
| `status` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `communication_audience`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `communication_channel`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `communication_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `dark_mode_pref`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `data_source`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `value` | `text` |  Unique |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `data_source_import`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `source` | `text` |  |
| `source_year` | `text` |  |
| `imported_at` | `timestamptz` |  |
| `imported_by` | `uuid` |  Nullable |
| `records_added` | `int4` |  |
| `records_updated` | `int4` |  |
| `records_deprecated` | `int4` |  |
| `file_name` | `text` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `discoverability`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `event`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  |
| `name` | `text` |  |
| `date` | `timestamptz` |  Nullable |
| `timezone` | `text` |  Nullable |
| `venue` | `text` |  Nullable |
| `type` | `text` |  Nullable |
| `headcount_target` | `int4` |  Nullable |
| `status` | `text` |  Nullable |
| `discoverability` | `text` |  Nullable |
| `join_policy` | `text` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `event_role`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `event_session`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  |
| `name` | `text` |  |
| `starts_at` | `timestamptz` |  Nullable |
| `ends_at` | `timestamptz` |  Nullable |
| `timezone` | `text` |  Nullable |
| `venue` | `text` |  Nullable |
| `type` | `text` |  Nullable |
| `headcount_target` | `int4` |  Nullable |
| `capacity` | `int4` |  Nullable |
| `is_optional` | `bool` |  |
| `requires_separate_rsvp` | `bool` |  |
| `status` | `text` |  |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `event_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `event_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `feature_flag`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  |
| `flag_key` | `text` |  |
| `flag_value` | `text` |  |
| `flag_type` | `text` |  |
| `source` | `text` |  |
| `note` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `deleted_at` | `timestamptz` |  Nullable |

## Table `feature_flag_source`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `value` | `text` |  Unique |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `feature_flag_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `value` | `text` |  Unique |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `financial_visibility`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `font_choice`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `identity`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `person_id` | `uuid` |  Nullable |
| `provider` | `text` |  |
| `provider_user_id` | `text` |  |
| `email` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `identity_provider`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `invitation`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  Nullable |
| `tenant_id` | `uuid` |  Nullable |
| `sender_id` | `uuid` |  Nullable |
| `recipient_email` | `text` |  |
| `token` | `text` |  Unique |
| `status` | `text` |  Nullable |
| `expires_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `invitation_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `join_policy`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `join_request`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  |
| `person_id` | `uuid` |  |
| `status` | `text` |  Nullable |
| `trust_score` | `float8` |  Nullable |
| `reviewed_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `join_request_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `media`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  |
| `event_id` | `uuid` |  Nullable |
| `uploader_id` | `uuid` |  Nullable |
| `url` | `text` |  |
| `type` | `text` |  Nullable |
| `moderation_flag` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `media_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `membership`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `person_id` | `uuid` |  |
| `tenant_id` | `uuid` |  Nullable |
| `org_role` | `text` |  Nullable |
| `linked_member_id` | `uuid` |  Nullable |
| `status` | `text` |  Nullable |
| `engagement_score` | `float8` |  Nullable |
| `involvement_rung` | `int4` |  Nullable |
| `joined_at` | `timestamptz` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `org_group_id` | `uuid` |  Nullable |
| `financial_visibility` | `text` |  |

## Table `membership_role`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `membership_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `memory`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  Nullable |
| `author_id` | `uuid` |  Nullable |
| `media_id` | `uuid` |  Nullable |
| `caption` | `text` |  Nullable |
| `year` | `int4` |  Nullable |
| `visibility` | `text` |  Nullable |
| `tags` | `_text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `memory_visibility`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `merge_log`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `person_id_a` | `uuid` |  |
| `person_id_b` | `uuid` |  |
| `merged_at` | `timestamptz` |  Nullable |
| `merged_by` | `uuid` |  Nullable |
| `evidence` | `jsonb` |  Nullable |

## Table `notification_recipient_role`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `notification_rule_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `notification_trigger`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `rule_type` | `text` |  |
| `threshold` | `float8` |  Nullable |
| `channel` | `text` |  Nullable |
| `recipient_role` | `text` |  Nullable |
| `cooldown` | `interval` |  Nullable |
| `last_fired_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `org_group`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `text` |  |
| `group_admin_id` | `uuid` |  Nullable |
| `type` | `text` |  Nullable |
| `aggregate_view_only` | `bool` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `slug` | `text` |  Unique |
| `status` | `text` |  |
| `source` | `text` |  Nullable |
| `external_id` | `text` |  Nullable |
| `city` | `text` |  Nullable |
| `state` | `text` |  Nullable |
| `zip` | `text` |  Nullable |
| `website` | `text` |  Nullable |
| `last_verified_at` | `timestamptz` |  Nullable |
| `social_links` | `jsonb` |  Nullable |

## Table `org_group_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `value` | `text` |  Unique |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `org_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `payment`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `attendee_record_id` | `uuid` |  |
| `amount` | `numeric` |  |
| `method` | `text` |  Nullable |
| `status` | `text` |  Nullable |
| `processor_ref` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `payment_method`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `payment_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `payment_transaction_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `person`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `email` | `text` |  Unique |
| `photo_url` | `text` |  Nullable |
| `dark_mode_pref` | `text` |  Nullable |
| `giving_interest` | `bool` |  Nullable |
| `claimed` | `bool` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `social_profiles` | `jsonb` |  Nullable |
| `first_name` | `text` |  Nullable |
| `last_name` | `text` |  Nullable |
| `maiden_name` | `text` |  Nullable |
| `preferred_name` | `text` |  Nullable |
| `auth_user_id` | `uuid` |  Nullable |

## Table `plan_tier`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `slug` | `text` |  Nullable Unique |
| `billing_interval` | `text` |  Nullable |
| `price_cents` | `int4` |  |
| `trial_days` | `int4` |  |
| `is_public` | `bool` |  |
| `effective_from` | `timestamptz` |  |
| `effective_to` | `timestamptz` |  Nullable |
| `stripe_price_id` | `text` |  Nullable |

## Table `platform_role`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `platform_user`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `person_id` | `uuid` |  |
| `role` | `text` |  |
| `granted_by` | `uuid` |  Nullable |
| `granted_at` | `timestamptz` |  Nullable |
| `revoked_at` | `timestamptz` |  Nullable |
| `auth_user_id` | `uuid` |  Nullable |

## Table `rsvp_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `session_attendee`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `session_id` | `uuid` |  |
| `person_id` | `uuid` |  |
| `rsvp_status` | `text` |  Nullable |
| `rsvp_at` | `timestamptz` |  Nullable |
| `waitlist_position` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `session_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `session_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `sponsor`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  |
| `business_name` | `text` |  |
| `contact_person_id` | `uuid` |  Nullable |
| `tier` | `text` |  Nullable |
| `amount` | `numeric` |  Nullable |
| `fulfillment_status` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `sponsor_fulfillment_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `sponsor_tier`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `subgroup`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  |
| `name` | `text` |  |
| `type` | `text` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `subgroup_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `subscription`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tenant_id` | `uuid` |  |
| `plan_tier_id` | `text` |  |
| `status` | `text` |  |
| `stripe_customer_id` | `text` |  Nullable |
| `stripe_subscription_id` | `text` |  Nullable |
| `stripe_price_id` | `text` |  Nullable |
| `trial_ends_at` | `timestamptz` |  Nullable |
| `current_period_start` | `timestamptz` |  Nullable |
| `current_period_end` | `timestamptz` |  Nullable |
| `canceled_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `deleted_at` | `timestamptz` |  Nullable |

## Table `subscription_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `value` | `text` |  Unique |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `survey`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  |
| `questions` | `jsonb` |  Nullable |
| `responses` | `jsonb` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `tenant`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_group_id` | `uuid` |  Nullable |
| `name` | `text` |  |
| `slug` | `text` |  |
| `type` | `text` |  Nullable |
| `discoverability` | `text` |  Nullable |
| `join_policy` | `text` |  Nullable |
| `domain_restriction` | `text` |  Nullable |
| `verification_config` | `jsonb` |  Nullable |
| `plan_tier` | `text` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `tenant_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `tshirt_size`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `vendor_booking`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `event_id` | `uuid` |  |
| `vendor_profile_id` | `uuid` |  |
| `headcount` | `int4` |  Nullable |
| `cost` | `numeric` |  Nullable |
| `contract_url` | `text` |  Nullable |
| `status` | `text` |  Nullable |
| `rating` | `float8` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `vendor_booking_status`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

## Table `vendor_profile`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `contact_person_id` | `uuid` |  Nullable |
| `type` | `text` |  Nullable |
| `region` | `text` |  Nullable |
| `capacity` | `int4` |  Nullable |
| `pricing` | `jsonb` |  Nullable |
| `avg_rating` | `float8` |  Nullable |
| `verified` | `bool` |  Nullable |
| `discoverable` | `bool` |  Nullable |
| `deleted_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `vendor_type`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `text` | Primary |
| `label` | `text` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  |

