-- Applications and notifications schema for Job For All.
-- Run in Supabase SQL editor or via CLI migrations.

-- ── Applications ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.applications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id     UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  seeker_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'pending'
             CHECK (status IN ('pending', 'accepted', 'rejected')),
  cv_url     TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (job_id, seeker_id)
);

CREATE INDEX IF NOT EXISTS applications_job_id_idx
  ON public.applications (job_id);

CREATE INDEX IF NOT EXISTS applications_seeker_id_idx
  ON public.applications (seeker_id);

ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

-- Seekers can insert their own applications
CREATE POLICY applications_insert_seeker ON public.applications
  FOR INSERT
  WITH CHECK (auth.uid() = seeker_id);

-- Seekers can read their own applications
CREATE POLICY applications_select_seeker ON public.applications
  FOR SELECT
  USING (auth.uid() = seeker_id);

-- Employers can read applications for jobs they own
CREATE POLICY applications_select_employer ON public.applications
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE jobs.id = applications.job_id
        AND jobs.employer_id = auth.uid()
    )
  );

-- Employers can update status on applications for their jobs
CREATE POLICY applications_update_employer ON public.applications
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE jobs.id = applications.job_id
        AND jobs.employer_id = auth.uid()
    )
  );

-- ── Notifications ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  application_id UUID REFERENCES public.applications(id) ON DELETE SET NULL,
  type           TEXT NOT NULL DEFAULT 'general',
  title          TEXT NOT NULL,
  message        TEXT NOT NULL,
  read           BOOLEAN NOT NULL DEFAULT false,
  created_by     UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx
  ON public.notifications (user_id);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY notifications_select_own ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Employers can insert notifications for seekers who applied to their jobs
CREATE POLICY notifications_insert_employer ON public.notifications
  FOR INSERT
  WITH CHECK (
    auth.uid() = created_by
    AND EXISTS (
      SELECT 1
      FROM public.applications a
      JOIN public.jobs j ON j.id = a.job_id
      WHERE a.id = notifications.application_id
        AND a.seeker_id = notifications.user_id
        AND j.employer_id = auth.uid()
    )
  );

-- Users can mark their own notifications as read
CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);
