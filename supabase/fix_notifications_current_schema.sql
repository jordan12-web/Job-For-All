-- Fix notification policies for the current Job For All Supabase schema.
-- Run this in the Supabase SQL editor.

DROP POLICY IF EXISTS notifications_insert_employer ON public.notifications;

CREATE POLICY notifications_insert_employer ON public.notifications
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.applications a
      JOIN public.jobs j ON j.id = a.job_id
      WHERE a.seeker_id = notifications.user_id
        AND j.employer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS notifications_select_own ON public.notifications;

CREATE POLICY notifications_select_own ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS notifications_update_own ON public.notifications;

CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
