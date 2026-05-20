-- Exam Configuration and Marks Matrix schema (Postgres)

CREATE TABLE exam_configuration (
  config_id UUID PRIMARY KEY,
  course_code TEXT NOT NULL,
  exam_type TEXT NOT NULL,
  max_marks INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE question_rules (
  rule_id UUID PRIMARY KEY,
  config_id UUID NOT NULL REFERENCES exam_configuration(config_id) ON DELETE CASCADE,
  question_no TEXT NOT NULL,
  part TEXT,
  max_score INTEGER NOT NULL,
  choice_group TEXT,
  position INTEGER DEFAULT 0
);

CREATE TABLE student_marks_matrix (
  mark_id UUID PRIMARY KEY,
  config_id UUID NOT NULL REFERENCES exam_configuration(config_id) ON DELETE CASCADE,
  student_id TEXT NOT NULL,
  rule_id UUID NOT NULL REFERENCES question_rules(rule_id) ON DELETE CASCADE,
  marks_obtained NUMERIC(6,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(config_id, student_id, rule_id)
);

-- final aggregated CIA scores stored in student_master (example)
-- ALTER TABLE student_master ADD COLUMN cia1 NUMERIC(6,2);
