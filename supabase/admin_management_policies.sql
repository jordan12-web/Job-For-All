-- Optional admin management policies for Job For All.
-- Run this if the Admin Dashboard should be allowed to delete job posts.

DROP POLICY IF EXISTS jobs_delete_admin ON public.jobs;

CREATE POLICY jobs_delete_admin ON public.jobs
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1
      FROM public.users u
      WHERE u.id = auth.uid()
        AND u.role = 'admin'
    )
  );
