module.exports = {
  autodiscover: true,
  endpoint: '{{.Endpoint}}',
  gitAuthor: 'Development Bot <dev-bot@my-software-company.com>',
  onboardingConfig: {
    extends: ['config:recommended', ':disableDependencyDashboard', 'group:allNonMajor'],
  },
  onboardingConfigFileName: '.github/renovate.json',
  platform: 'github',
  token: '{{.InstallationToken}}',
  username: 'Coding-IA Test[bot]'
}
