-- schema designing normalization ?
CREATE TABLE IF NOT EXISTS users(
    id BIGSERIAL PRIMARY KEY,
    full_name TEXT NOT NULL, --No point deciding some random limit like 100 or 255.
    email TEXT NOT NULL UNIQUE, -- validation will be done by backend/frontend/business rules...
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
); 


CREATE TABLE IF NOT EXISTS projects(
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_project_owner
    FOREIGN KEY(owner_id)
    REFERENCES users(id)
    ON DELETE RESTRICT
);
-- RESTRICTING is for restricting the owner of a project to be deleted
-- ownership must be transferred before deletion of a user.


CREATE TABLE IF NOT EXISTS project_members(
    user_id BIGINT NOT NULL,
    project_id BIGINT NOT NULL,
    role_in_project TEXT NOT NULL, --ENUM IN FUTURE
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY(
        user_id,
        project_id
    ),

    CONSTRAINT fk_pm_project
    FOREIGN KEY(project_id)
    REFERENCES projects(id)
    ON DELETE CASCADE,

    CONSTRAINT fk_pm_user
    FOREIGN KEY(user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

    CONSTRAINT chk_role
    CHECK(
        role_in_project IN (
                'Owner',
                'Manager',
                'Developer',
                'Tester',
                'Viewer'
        )
    )

);



CREATE TABLE IF NOT EXISTS tasks(
    id BIGSERIAL PRIMARY KEY ,
    project_id BIGINT NOT NULL,
    created_by_id BIGINT NOT NULL,
    assignee_id BIGINT, --task can be not assigned to anyone
    parent_task_id BIGINT, --root task can be there
    title TEXT NOT NULL,
    description TEXT ,
    status TEXT NOT NULL DEFAULT 'Todo',
    due_date DATE,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_task_project
    FOREIGN KEY(project_id)
    REFERENCES projects(id)
    ON DELETE CASCADE,

    CONSTRAINT fk_task_creator
    FOREIGN KEY(created_by_id)
    REFERENCES users(id)
    ON DELETE RESTRICT, -- project history

    CONSTRAINT fk_task_assignee
    FOREIGN KEY(assignee_id)
    REFERENCES users(id)
    ON DELETE SET NULL,

    CONSTRAINT fk_parent_task
    FOREIGN KEY(parent_task_id)
    REFERENCES tasks(id)
    ON DELETE SET NULL,

    CONSTRAINT chk_task_status
    CHECK(
        status IN (
            'Todo',
            'In Progress',
            'Review',
            'Completed',
            'Cancelled'
        )
    )
);


CREATE TABLE IF NOT EXISTS comments(
    id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comment_task
    FOREIGN KEY(task_id)
    REFERENCES tasks(id)
    ON DELETE CASCADE,

    CONSTRAINT fk_comment_user
    FOREIGN KEY(user_id)
    REFERENCES users(id)
    ON DELETE RESTRICT -- project history 
);
-- HISTORY SHOULD NOT BE COMPROMISE OF A DATATYPE



CREATE TABLE IF NOT EXISTS attachments(
    id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL,
    filename TEXT NOT NULL,
    file_url TEXT NOT NULL,
    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_attachment_task
    FOREIGN KEY(task_id)
    REFERENCES tasks(id)
    ON DELETE CASCADE

);