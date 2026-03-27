# Sleep Nudger Product Spec

## Purpose

Sleep Nudger is a lightweight local-first mobile app that helps users go to bed on time with calm reminders that become firmer as bedtime arrives.

## MVP Goal

Deliver the smallest usable bedtime nudge loop:

- fast first-run setup
- bedtime and reminder lead-time configuration
- gentle reminder before bedtime
- stronger reminder at bedtime
- in-app snooze with a three-snooze limit
- next-morning success or failure summary
- local streak tracking

## Non-Goals

The MVP does not include:

- sleep tracking
- medical guidance
- account system
- backend or cloud sync
- analytics
- buddy notifications
- screen-time blocking
- AI features
- charts or long-term dashboards

## Core Rules

- default grace period is 20 minutes after bedtime
- success counts only when the user confirms bedtime before the grace window ends
- streak increments on success and resets on failure
- summary resolves after 6:00 AM local time when the app is opened
- all state is stored locally on device

## Primary Screens

- Onboarding: welcome, bedtime picker, reminder lead-time picker, save
- Home: tonight’s bedtime, next reminder time, streak, bedtime confirmation, snooze, settings entry
- Morning Summary: success or failure message, streak, continue button
- Settings: bedtime, lead time, gentle reminders toggle, sound/vibration toggle

## Tone

- calm
- warm
- direct
- non-medical
- never guilt-heavy
