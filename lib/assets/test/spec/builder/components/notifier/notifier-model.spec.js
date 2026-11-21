var NotifierModel = require('builder/components/notifier/notifier-model.js');

describe('components/notifier/notifier-model', function () {
  var model = new NotifierModel({}, {});

  describe('.update', function () {
    it('returns the notification so success handlers can read it', function () {
      var updated = model.update({ status: 'success' });

      expect(updated).toBe(model);
      expect(model.get('status')).toEqual('success');
    });
  });

  describe('.getInfo', function () {
    model.updateInfo('< & Hello >');

    it('should return current info', function () {
      var info = model.getInfo();
      expect(info).toBe('< & Hello >');
    });
  });
});
