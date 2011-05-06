class UserCourseAssociation < ActiveRecord::Base
  include AASM
  belongs_to :user
  belongs_to :course
  enumerate :role

  # Filtra por papéis (lista)
  scope :with_roles, lambda { |roles|
    unless roles.empty?
      where(:role_id => roles.flatten)
    end
  }

  # Filtra por palavra-chave (procura em User)
  scope :with_keyword, lambda { |keyword|
    if not keyword.empty? and keyword.size > 3
      where("users.first_name LIKE :keyword " + \
        "OR users.last_name LIKE :keyword " + \
        "OR users.login LIKE :keyword", {:keyword => "%#{keyword}%"}).
        include(:user).includes(:user_space_associations).indluce(:space)
    end
  }

  scope :recent, lambda { where("created_at >= ?", 1.week.ago) }
  scope :approved, where(:state => 'approved')
  scope :invited, where(:state => 'invited')

  # Máquina de estados para moderação das dos usuários nos courses.
  aasm_column :state

  aasm_initial_state :waiting

  aasm_state :waiting
  aasm_state :invited, :enter => :send_course_invitation_notification
  aasm_state :approved, :enter => :create_hierarchy_associations
  aasm_state :rejected
  aasm_state :failed

  aasm_event :invite do
    transitions :to => :invited, :from => [:waiting]
  end

  aasm_event :approve do
    transitions :to => :approved, :from => [:waiting]
  end

  aasm_event :accept do
    transitions :to => :approved, :from => [:invited]
  end

  aasm_event :reject do
    transitions :to => :rejected, :from => [:waiting]
  end

  aasm_event :deny do
    transitions :to => :rejected, :from => [:invited]
  end

  aasm_event :fail do
    transitions :to => :failed, :from => [:waiting]
  end

  validates_uniqueness_of :user_id, :scope => :course_id

  # Verificar se há UCA com estado pending para um determinado usuário.
  # Opcionalmente pode-se passar o curso.
  def self.has_invitation_for?(user, course = nil)
    conditions = { :state => 'invited', :user_id => user }
    conditions[:course_id] = course unless course.nil?

    UserCourseAssociation.where(conditions).count > 0
  end

  def send_course_invitation_notification
    UserNotifier.course_invitation_notification(self.user, self.course).deliver
  end

  protected

  def create_hierarchy_associations
    self.course.create_hierarchy_associations(self.user) if self.invited?
  end
end
