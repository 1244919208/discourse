import { click, render, waitFor } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender from "discourse/tests/helpers/create-pretender";
import { createFile } from "discourse/tests/helpers/qunit-helpers";
import ChatComposerUploads from "discourse/plugins/chat/discourse/components/chat-composer-uploads";

const fakeUpload = {
  type: ".png",
  extension: "png",
  name: "myfile.png",
  short_path: "/images/avatar.png",
};

const mockUploadResponse = {
  extension: "jpeg",
  filesize: 126177,
  height: 800,
  human_filesize: "123 KB",
  id: 202,
  original_filename: "avatar.PNG.jpg",
  retain_hours: null,
  short_path: "/images/avatar.png",
  short_url: "upload://yoj8pf9DdIeHRRULyw7i57GAYdz.jpeg",
  thumbnail_height: 320,
  thumbnail_width: 690,
  url: "/images/avatar.png",
  width: 1920,
};

function setupUploadPretender() {
  pretender.post(
    "/uploads.json",
    () => {
      return [200, { "Content-Type": "application/json" }, mockUploadResponse];
    },
    500 // this delay is important to slow down the uploads a bit so we can click elements in the UI like the cancel button
  );
}

module("Discourse Chat | Component | chat-composer-uploads", function (hooks) {
  setupRenderingTest(hooks);

  test("loading uploads from an outside source (e.g. draft or editing message)", async function (assert) {
    const self = this;

    this.existingUploads = [fakeUpload];

    await render(
      <template>
        <ChatComposerUploads
          @existingUploads={{self.existingUploads}}
          @fileUploadElementId="chat-widget-uploader"
        />
      </template>
    );

    assert.dom(".chat-composer-upload").exists({ count: 1 });
  });

  test("upload starts and completes", async function (assert) {
    const self = this;

    setupUploadPretender();
    this.set("onUploadChanged", () => {});

    await render(
      <template>
        <ChatComposerUploads
          @fileUploadElementId="chat-widget-uploader"
          @onUploadChanged={{self.onUploadChanged}}
        />
      </template>
    );

    const done = assert.async();
    this.appEvents = this.container.lookup("service:app-events");
    this.appEvents.on(
      "upload-mixin:chat-composer-uploader:upload-success",
      (fileName, upload) => {
        assert.strictEqual(fileName, "avatar.png");
        assert.deepEqual(upload, mockUploadResponse);
        done();
      }
    );
    this.appEvents.trigger(
      "upload-mixin:chat-composer-uploader:add-files",
      createFile("avatar.png")
    );

    await waitFor(".chat-composer-upload");

    assert.dom(".chat-composer-upload").exists({ count: 1 });
  });

  test("removing a completed upload", async function (assert) {
    const self = this;

    this.set("changedUploads", null);
    this.set("onUploadChanged", () => {});

    this.existingUploads = [fakeUpload];

    await render(
      <template>
        <ChatComposerUploads
          @existingUploads={{self.existingUploads}}
          @fileUploadElementId="chat-widget-uploader"
          @onUploadChanged={{self.onUploadChanged}}
        />
      </template>
    );

    assert.dom(".chat-composer-upload").exists({ count: 1 });

    await click(".chat-composer-upload__remove-btn");

    assert.dom(".chat-composer-upload").exists({ count: 0 });
  });

  test("cancelling in progress upload", async function (assert) {
    const self = this;

    setupUploadPretender();

    this.set("changedUploads", null);
    this.set("onUploadChanged", (uploads) => {
      this.set("changedUploads", uploads);
    });

    await render(
      <template>
        <ChatComposerUploads
          @fileUploadElementId="chat-widget-uploader"
          @onUploadChanged={{self.onUploadChanged}}
        />
      </template>
    );

    const image = createFile("avatar.png");
    const done = assert.async();
    this.appEvents = this.container.lookup("service:app-events");

    this.appEvents.on(
      `upload-mixin:chat-composer-uploader:upload-cancelled`,
      (fileId) => {
        assert.true(
          fileId.includes("chat-composer-uploader-avatar/"),
          "upload was cancelled"
        );
        done();
      }
    );

    this.appEvents.trigger(
      "upload-mixin:chat-composer-uploader:add-files",
      image
    );

    await waitFor(".chat-composer-upload");
    assert.dom(".chat-composer-upload").exists({ count: 1 });

    await click(".chat-composer-upload__remove-btn");
    assert.dom(".chat-composer-upload").doesNotExist();
  });
});
