RSpec.describe BaseModel do
  it 'has a version number' do
    expect(BaseModel::VERSION).not_to be nil
  end
end
