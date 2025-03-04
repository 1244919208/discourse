import { registerRichEditorExtension } from "discourse/lib/composer/rich-editor-extensions";
import underline from "./underline";

/**
 * List of default extensions
 * ProsemirrorEditor autoloads them when includeDefault=true (the default)
 *
 * @type {RichEditorExtension[]}
 */
const defaultExtensions = [underline];

defaultExtensions.forEach(registerRichEditorExtension);
